# Controller for Digital Objects
#
require 'solr/query'

class ObjectsController < BaseObjectsController
  include Blacklight::AccessControls::Catalog
  include DRI::Duplicable
  include Preservation::PreservationHelpers

  before_action :authenticate_user_from_token!, except: [:show, :citation]
  before_action :authenticate_user!, except: [:show, :citation]
  before_action :read_only, except: [:show, :citation, :retrieve]
  before_action ->(id=params[:id]) { locked(id) }, except: [:show, :citation, :new, :create, :retrieve]

  # Displays the New Object form
  #
  def new
    @collection = params[:collection]

    locked(@collection); return if performed?

    @object = DRI::DigitalObject.with_standard :qdc
    @object.creator = ['']

    if params[:is_sub_collection].present? && params[:is_sub_collection] == 'true'
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

    if @document.published? && @document.doi.present?
      flash[:alert] = "#{t('dri.flash.alert.doi_published_warning')}".html_safe
    end

    respond_to do |format|
      format.html
      format.json { render json: @object }
    end
  end

  def show
    enforce_permissions!('show_digital_object', params[:id])
    @object = retrieve_object!(params[:id])

    respond_to do |format|
      format.html { redirect_to(catalog_url(@object.alternate_id)) }
      format.endnote { render plain: @object.export_as_endnote, layout: false }
      format.json do
        json = @object.as_json
        solr_doc = SolrDocument.find(@object.alternate_id)

        json['licence'] = DRI::Formatters::Json.licence(solr_doc)
        json['doi'] = DRI::Formatters::Json.dois(solr_doc)
        json['related_objects'] = solr_doc.object_relationships_as_json
        render json: json
      end
      format.zip do
        if current_user
          Resque.enqueue(CreateArchiveJob, params[:id], current_user.email)

          flash[:notice] = t('dri.flash.notice.archiving')
          redirect_back(fallback_location: root_path)
        else
          flash[:alert] = t('dri.flash.alert.archiving_login')
          redirect_back(fallback_location: root_path)
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

    if params[:digital_object][:governing_collection_id].present?
      collection = retrieve_object(params[:digital_object][:governing_collection_id])
      @object.governing_collection = collection
    end

    @object.assign_attributes(update_params)

    unless @object.valid?
      flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
      format.html { render action: 'edit' }
      return
    end

    DRI::DigitalObject.transaction do
      @object.increment_version

      if doi
        doi.update_metadata(update_params.select { |key, _value| doi.metadata_fields.include?(key) })
        new_doi_if_required(@object, doi, 'metadata updated')
      end

      respond_to do |format|
        checksum_metadata(@object)

        unless @object.save
          flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
          format.html { render action: 'edit' }
          raise ActiveRecord::Rollback, @object.errors.full_messages.inspect
        end

        post_save do
          mint_or_update_doi(@object, doi) if doi
        end

        flash[:notice] = t('dri.flash.notice.metadata_updated')
        format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
        format.json { render json: @object }
      end
    end
  end

  def citation
    enforce_permissions!('show_digital_object', params[:id])

    @object = retrieve_object!(params[:id])
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    if params[:digital_object][:read_users_string].present?
      params[:digital_object][:read_users_string] = params[:digital_object][:read_users_string].to_s.downcase
    end
    if params[:digital_object][:edit_users_string].present?
      params[:digital_object][:edit_users_string] = params[:digital_object][:edit_users_string].to_s.downcase
    end

    if params[:digital_object][:governing_collection].present?
      params[:digital_object][:governing_collection] = retrieve_object(params[:digital_object][:governing_collection])
      # governing_collection present and also whether this is a documentation object?
      if params[:digital_object][:documentation_for].present?
        params[:digital_object][:documentation_for] = retrieve_object(params[:digital_object][:documentation_for])
      end
    end

    enforce_permissions!('create_digital_object', params[:digital_object][:governing_collection].alternate_id)
    locked(params[:digital_object][:governing_collection].alternate_id); return if performed?

    if params[:digital_object][:documentation_for].present?
      create_from_form :documentation
    elsif params[:metadata_file].present?
      create_from_upload
    else
      create_from_form
    end

    checksum_metadata(@object)
    supported_licences

    if @object.valid? && @object.save
      post_save do
        create_reader_group if @object.collection?
      end

      respond_to do |format|
        format.html do
          flash[:notice] = t('dri.flash.notice.digital_object_ingested')
          redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id
        end
        format.json do
          response = { pid: @object.alternate_id }
          response[:warning] = @warnings if @warnings

          render json: response, location: my_collections_url(@object.alternate_id), status: :created
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
      raise Blacklight::AccessControls::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '')
    end

    # Do the preservation actions
    @object.increment_version

    assets = []
    @object.generic_files.map { |gf| assets << "#{gf.alternate_id}_#{gf.label}" }

    preservation = Preservation::Preservator.new(@object)
    preservation.update_manifests(
      deleted: {
        'content' => assets,
        'metadata' => ['descMetadata.xml']
        }
    )
    collection_id = @object.governing_collection.alternate_id
    @object.delete

    flash[:notice] = t('dri.flash.notice.object_deleted')

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: collection_id }
    end
  end

  def retrieve
    id = params[:id]
    object = SolrDocument.find(id)

    if object.present?
      if can?(:read, object)
        if File.file?(File.join(Settings.dri.downloads, params[:archive]))
          response.headers['Content-Length'] = File.size?(params[:archive]).to_s
          send_file File.join(Settings.dri.downloads, params[:archive]),
                type: "application/zip",
                stream: true,
                buffer: 4096,
                disposition: "attachment; filename=\"#{id}.zip\";",
                url_based_filename: true

          if object.published?
            Gabba::Gabba.new(GA.tracker, request.host).event(object.root_collection_id, "Download", object.alternate_id, 1, true)
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
      @object.increment_version
      @object.save

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve

      # if this object is in a sub-collection, we need to set that collection status
      # to reviewed so that a publish job will run on the collection
      set_ancestors_reviewed if params[:status] == 'reviewed'
    end

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.metadata_updated')
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
      format.json do
        response = { id: @object.alternate_id, status: @object.status }
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

      @object = DRI::DigitalObject.with_standard xml_ds.metadata_standard
      @object.depositor = current_user.to_s
      @object.assign_attributes create_params

      @object.update_metadata xml
    end

    # If no standard parameter then default to :qdc
    # allow to create :documentation and :marc objects (improve merging into marc-nccb branch)
    #
    def create_from_form(standard = nil)
      @object = if standard
                  DRI::DigitalObject.with_standard(standard)
                else
                  DRI::DigitalObject.with_standard(:qdc)
                end
      @object.depositor = current_user.to_s
      @object.assign_attributes create_params
    end

    def create_reader_group
      group = UserGroup::Group.new(
        name: @object.alternate_id,
        description: "Default Reader group for collection #{@object.alternate_id}"
      )
      group.reader_group = true
      group.save
    end

    def metadata_standard
      standard = @object.descMetadata.class.to_s.downcase.split('::').last

      standard == 'documentation' ? 'qualifieddublincore' : standard
    end

    def post_save
      warn_if_has_duplicates(@object)
      retrieve_linked_data if AuthoritiesConfig
      record_version_committer(@object, current_user)

      yield

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(['descMetadata'])
    end

    def retrieve_linked_data
      DRI.queue.push(LinkedDataJob.new(@object.alternate_id)) if @object.geographical_coverage.present? || @object.coverage.present?
    rescue Exception => e
      Rails.logger.error "Unable to submit linked data job: #{e.message}"
    end

    def set_ancestors_reviewed
      governing_collection = @object.governing_collection

      while governing_collection.root_collection? == false
        if governing_collection.status == 'draft'
          governing_collection.status = 'reviewed'
          governing_collection.increment_version
          governing_collection.save

          # Do the preservation actions
          preservation = Preservation::Preservator.new(governing_collection)
          preservation.preserve
        end

        governing_collection = governing_collection.governing_collection
      end
    end

end
