# Controller for Digital Objects
#
require 'solr/query'

class ObjectsController < BaseObjectsController
  include DRI::MetadataBehaviour

  before_action :authenticate_user_from_token!, except: [:show, :citation]
  before_action :authenticate_user!, except: [:show, :citation]
  before_action :read_only, except: [:index, :show, :citation, :related]

  # Displays the New Object form
  #
  def new
    @collection = params[:collection]

    @object = DRI::Batch.with_standard :qdc
    @object.creator = ['']

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

    doi.update_metadata(params[:batch].select { |key, _value| doi.metadata_fields.include?(key) }) if doi

    @object.object_version = @object.object_version.to_i + 1
    updated = @object.update_attributes(update_params)

    # purge params from update action
    purge_params

    respond_to do |format|
      if updated
        checksum_metadata(@object)
        @object.save

        warn_if_duplicates
        retrieve_linked_data

        actor.version_and_record_committer
        update_doi(@object, doi, 'metadata update') if doi && doi.changed?

        # Do the preservation actions
        preservation = Preservation::Preservator.new(@object)
        preservation.preserve(false, false,['descMetadata','properties'])

        flash[:notice] = t('dri.flash.notice.metadata_updated')
        format.html { redirect_to controller: 'catalog', action: 'show', id: @object.id }
      else
        flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
        format.html { render action: 'edit' }
      end
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

    if params[:batch][:documentation_for].present?
      create_from_form :documentation
    elsif params[:metadata_file].present?
      create_from_upload
    else
      create_from_form
    end

    checksum_metadata(@object)

    supported_licences

    @object.object_version = 1

    if @object.valid? && @object.save
      warn_if_duplicates

      create_reader_group if @object.collection?
      retrieve_linked_data

      actor.version_and_record_committer

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(true, true, ['descMetadata','properties'])

      respond_to do |format|
        format.html do
          flash[:notice] = t('dri.flash.notice.digital_object_ingested')
          redirect_to controller: 'catalog', action: 'show', id: @object.id
        end
        format.json do
          response = { pid: @object.id }
          response[:warning] = @warnings if @warnings

          render json: response, location: catalog_url(@object.id), status: :created
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

    if @object.status != 'published'
      # Do the preservation actions
      @object.object_version = @object.object_version.to_i + 1
      assets = []
      @object.generic_files.map { |gf| assets << "#{gf.id}_#{gf.label}" }
      preservation = Preservation::Preservator.new(@object)
      preservation.update_manifests(:deleted => {'content' => assets, 'metadata' => ['descMetadata.xml','permissions.rdf','properties.xml','resource.rdf']})

      @object.delete

      flash[:notice] = t('dri.flash.notice.object_deleted')
    else
      raise Hydra::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '')
    end

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'index' }
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

          item = solr_doc.extract_metadata(params[:metadata])
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
          fq: "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:false
               AND #{Solrizer.solr_name('status', :stored_searchable, type: :symbol)}:published",
          mlt: 'true',
          :'mlt.fl' => "#{Solrizer.solr_name('subject', :stored_searchable, type: :string)},
                        #{Solrizer.solr_name('subject', :stored_searchable, type: :string)}",
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

  def status
    enforce_permissions!('edit', params[:id])

    @object = retrieve_object!(params[:id])

    return if request.get?

    raise DRI::Exceptions::BadRequest if @object.collection?

    unless @object.status == 'published'
      @object.status = params[:status] if params[:status].present?
      @object.object_version = @object.object_version.to_i + 1
      @object.save

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(false, false, ['properties'])
    end

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.metadata_updated')
      format.html { redirect_to controller: 'catalog', action: 'show', id: @object.id }
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
      xml = load_xml(params[:metadata_file])
      standard = metadata_standard_from_xml(xml)

      @object = DRI::Batch.with_standard standard
      @object.depositor = current_user.to_s
      @object.update_attributes create_params

      set_metadata_datastream(@object, xml)
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
          surrogates.each do |file, _loc|
            file_list[file] = url_for(object_file_url(
              object_id: doc.id, id: file_doc.id, surrogate: file)
            )
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

    def retrieve_linked_data
      if AuthoritiesConfig
        begin
          Sufia.queue.push(LinkedDataJob.new(@object.id)) if @object.geographical_coverage.present?
        rescue Exception => e
          Rails.logger.error "Unable to submit linked data job: #{e.message}"
        end
      end
    end

end
