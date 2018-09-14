# Controller for Digital Objects
#
require 'solr/query'

class ObjectsController < BaseObjectsController
  include DRI::Duplicable

  Mime::Type.register "application/zip", :zip

  before_action :authenticate_user_from_token!, except: [:show, :citation]
  before_action :authenticate_user!, except: [:show, :citation]
  before_action :read_only, except: [:index, :show, :citation, :related, :retrieve]
  before_action ->(id=params[:id]) { locked(id) }, except: [:index, :show, :citation, :related, :new, :create, :retrieve]

  # Displays the New Object form
  #
  def new
    @collection = params[:collection]

    locked(@collection); return if performed?

    @object = DRI::Batch.with_standard :qdc
    @object.creator = ['']

    if params[:is_sub_collection].present? && params[:is_sub_collection] == 'true'
      @object.object_type = ['Collection']
      @object.type = ['Collection']
    end

    supported_licences
  end

  # Edits an existing model.
  #
  def edit
    enforce_permissions!('edit', params[:id])

    supported_licences

    @object = retrieve_object!(params[:id])
    @object.creator = [''] unless @object.creator[0]
    @standard = metadata_standard

    # used for crumbtrail
    @document = SolrDocument.new(@object.to_solr)

    respond_to do |format|
      format.html
      format.json { render json: @object }
    end
  end

  def show
    enforce_permissions!('show_digital_object', params[:id])

    @object = retrieve_object!(params[:id])

    respond_to do |format|
      format.html { redirect_to(catalog_url(@object.id)) }
      format.endnote { render text: @object.export_as_endnote, layout: false }
      format.zip do
        if current_user
          Resque.enqueue(CreateArchiveJob, params[:id], current_user.email)

          flash[:notice] = t('dri.flash.notice.archiving')
          redirect_to :back
        else
          flash[:alert] = t('dri.flash.alert.archiving_login')
          redirect_to :back
        end
      end
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    enforce_permissions!('edit', params[:id])

    supported_licences

    @object = retrieve_object!(params[:id])

    if params[:batch][:governing_collection_id].present?
      collection = DRI::Batch.find(params[:batch][:governing_collection_id])
      @object.governing_collection = collection
    end

    @object.object_version ||= '1'
    @object.increment_version

    unless @object.update_attributes(update_params)
      purge_params
      flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
      format.html { render action: 'edit' }
      return
    end

    doi.update_metadata(params[:batch].select { |key, _value| doi.metadata_fields.include?(key) }) if doi

    # purge params from update action
    purge_params

    respond_to do |format|
      checksum_metadata(@object)
      @object.save

      post_save(false) do
        update_doi(@object, doi, 'metadata update') if doi && doi.changed?
      end

      flash[:notice] = t('dri.flash.notice.metadata_updated')
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.id }
      format.json { render json: @object }
    end
  end

  def citation
    enforce_permissions!('show_digital_object', params[:id])

    @object = retrieve_object!(params[:id])
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    params[:batch][:read_users_string] = params[:batch][:read_users_string].to_s.downcase
    params[:batch][:edit_users_string] = params[:batch][:edit_users_string].to_s.downcase

    if params[:batch][:governing_collection].present?
      params[:batch][:governing_collection] = DRI::Batch.find(params[:batch][:governing_collection])
      # governing_collection present and also whether this is a documentation object?
      if params[:batch][:documentation_for].present?
        params[:batch][:documentation_for] = DRI::Batch.find(params[:batch][:documentation_for])
      end
    end

    enforce_permissions!('create_digital_object', params[:batch][:governing_collection].id)
    locked(params[:batch][:governing_collection].id); return if performed?

    if params[:batch][:documentation_for].present?
      create_from_form :documentation
    elsif params[:metadata_file].present?
      create_from_upload
    else
      create_from_form
    end

    checksum_metadata(@object)
    supported_licences
    @object.object_version = '1'

    if @object.valid? && @object.save
      post_save(true) do
        create_reader_group if @object.collection?
      end

      respond_to do |format|
        format.html do
          flash[:notice] = t('dri.flash.notice.digital_object_ingested')
          redirect_to controller: 'my_collections', action: 'show', id: @object.id
        end
        format.json do
          response = { pid: @object.id }
          response[:warning] = @warnings if @warnings

          render json: response, location: my_collections_url(@object.id), status: :created
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
          raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata_input')
        end
        format.json do
          raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata_input')
        end
      end
    end
  end

  def destroy
    enforce_permissions!('edit', params[:id])

    @object = retrieve_object!(params[:id])

    if @object.status == 'published' && !current_user.is_admin?
      raise Hydra::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '')
    end

    # Do the preservation actions
    @object.object_version || '1'
    @object.increment_version

    assets = []
    @object.generic_files.map { |gf| assets << "#{gf.id}_#{gf.label}" }

    preservation = Preservation::Preservator.new(@object)
    preservation.update_manifests(
      deleted: {
        'content' => assets,
        'metadata' => ['descMetadata.xml','permissions.rdf','properties.xml','resource.rdf']
        }
    )
    collection_id = @object.governing_collection_id
    @object.delete

    flash[:notice] = t('dri.flash.notice.object_deleted')

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: collection_id }
    end
  end

  def index
    @list = []

    if params[:objects].present?
      solr_query = ActiveFedora::SolrService.construct_query_for_ids(
        params[:objects].map { |o| o.values.first }
      )
      results = Solr::Query.new(solr_query)

      while results.has_more?
        docs = results.pop
        docs.each do |doc|
          solr_doc = SolrDocument.new(doc)

          next unless solr_doc.published?

          item = Rails.cache.fetch("get_objects-#{solr_doc.id}-#{solr_doc['system_modified_dtsi']}") do
            solr_doc.extract_metadata(params[:metadata])
          end

          item.merge!(find_assets_and_surrogates(solr_doc))
          @list << item
        end

        raise DRI::Exceptions::NotFound if @list.empty?
      end

    else
      logger.error "No objects in params #{params.inspect}"
      raise DRI::Exceptions::BadRequest
    end

    respond_to do |format|
      format.json {}
    end
  end

  def related
    enforce_permissions!('show_digital_object', params[:object])

    count = if params[:count].present? && numeric?(params[:count])
              params[:count]
            else
              3
            end

    if params[:object].present?
      solr_query = ActiveFedora::SolrService.construct_query_for_pids([params[:object]])
      result = ActiveFedora::SolrService.instance.conn.get(
        'select',
        params: {
          q: solr_query, qt: 'standard',
          fq: "#{ActiveFedora.index_field_mapper.solr_name('is_collection', :stored_searchable, type: :string)}:false
               AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:published",
          mlt: 'true',
          :'mlt.fl' => "#{ActiveFedora.index_field_mapper.solr_name('subject', :stored_searchable, type: :string)},
                        #{ActiveFedora.index_field_mapper.solr_name('subject', :stored_searchable, type: :string)}",
          :'mlt.count' => count,
          fl: 'id,score',
          :'mlt.match.include' => 'false'
        }
      )
    end

    # TODO: fixme!
    @related = []
    if result && result['moreLikeThis'] && result['moreLikeThis'].first &&
       result['moreLikeThis'].first[1] && result['moreLikeThis'].first[1]['docs']
      result['moreLikeThis'].first[1]['docs'].each do |item|
        @related << item
      end
    end

    respond_to do |format|
      format.json {}
    end
  end

  def retrieve
    id = params[:id]
    begin
      object = retrieve_object!(id)
    rescue ActiveFedora::ObjectNotFoundError
      flash[:error] = t('dri.flash.error.download_no_file')
    end

    if object.present?
      if (can? :read, object)
        if File.file?(File.join(Settings.dri.downloads, params[:archive]))
          response.headers['Content-Length'] = File.size?(params[:archive]).to_s
          send_file File.join(Settings.dri.downloads, params[:archive]),
                type: "application/zip",
                stream: true,
                buffer: 4096,
                disposition: "attachment; filename=\"#{id}.zip\";",
                url_based_filename: true

          if object.published?
            Gabba::Gabba.new(GA.tracker, request.host).event(object.root_collection.first, "Download", object.id, 1, true)
          end
          file_sent = true
        else
          flash[:error] = t('dri.flash.error.download_no_file')
        end
      else
        flash[:alert] = t('dri.flash.alert.read_permission')
      end
    end

    unless file_sent
      respond_to do |format|
        format.html { redirect_to controller: 'catalog', action: 'index' }
      end
    end
  end

  def status
    enforce_permissions!('edit', params[:id])

    @object = retrieve_object!(params[:id])

    return if request.get?

    raise DRI::Exceptions::BadRequest if @object.collection?

    if @object.status != 'published' || current_user.is_admin?
      @object.status = params[:status] if params[:status].present?
      @object.object_version ||= '1'
      @object.increment_version
      @object.save

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(false, false, ['properties'])
    end

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.metadata_updated')
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.id }
      format.json do
        response = { id: @object.id, status: @object.status }
        response[:warning] = @warnings if @warnings
        render json: response, status: :accepted
      end
    end
  end

  def set_licence
    enforce_permissions!('edit', params[:id])

    super
  end

  private

    def create_from_upload
      xml_ds = XmlDatastream.new
      xml = xml_ds.load_xml(params[:metadata_file])

      @object = DRI::Batch.with_standard(xml_ds.metadata_standard)
      @object.depositor = current_user.to_s
      @object.update_attributes create_params

      @object.update_metadata xml
    end

    # If no standard parameter then default to :qdc
    # allow to create :documentation and :marc objects (improve merging into marc-nccb branch)
    #
    def create_from_form(standard = nil)
      @object = if standard
                  DRI::Batch.with_standard(standard)
                else
                  DRI::Batch.with_standard(:qdc)
                end
      @object.depositor = current_user.to_s
      @object.update_attributes create_params
    end

    def create_reader_group
      group = UserGroup::Group.new(
        name: @object.id.to_s,
        description: "Default Reader group for collection #{@object.id}"
      )
      group.reader_group = true
      group.save
    end

    def find_assets_and_surrogates(doc)
      item = {}
      item['files'] = []

      # Get files
      if can? :read, doc
        files = doc.assets

        files.each do |file_doc|
          file_list = {}

          if (doc.read_master? && can?(:read, doc)) || can?(:edit, doc)
            url = url_for(file_download_url(doc.id, file_doc.id))
            file_list['masterfile'] = url
          end

          timeout = 60 * 60 * 24 * 7
          surrogates = doc.surrogates(file_doc.id, timeout)
          surrogates.each do |file, loc|
            file_list[file] = loc
          end

          item['files'].push(file_list)
        end
      end

      item
    end

    def metadata_standard
      standard = @object.descMetadata.class.to_s.downcase.split('::').last

      standard == 'documentation' ? 'qualifieddublincore' : standard
    end

    def numeric?(number)
      Integer(number) rescue false
    end

    def post_save(create)
      warn_if_has_duplicates(@object)
      retrieve_linked_data
      version_and_record_committer(@object, current_user)

      yield

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(create, create, ['descMetadata','properties'])
    end

    def retrieve_linked_data
      if AuthoritiesConfig
        begin
          DRI.queue.push(LinkedDataJob.new(@object.id)) if @object.geographical_coverage.present?
        rescue Exception => e
          Rails.logger.error "Unable to submit linked data job: #{e.message}"
        end
      end
    end

end
