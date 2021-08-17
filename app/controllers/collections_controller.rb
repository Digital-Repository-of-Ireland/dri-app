# Controller for the Collection model
#
require 'storage/cover_images'
require 'validators'

class CollectionsController < BaseObjectsController
  include Blacklight::AccessControls::Catalog
  include DRI::Duplicable

  before_action :authenticate_user_from_token!, except: [:cover]
  before_action :authenticate_user!, except: [:cover]
  before_action :authorize_cm!, only: [:new, :create]
  before_action :check_for_cancel, only: [:create, :update, :add_cover_image]
  before_action :read_only, except: [:index, :cover]
  before_action ->(id=params[:id]) { locked(id) }, except: %i|index cover lock new create|

  # Was this action canceled by the user?
  def check_for_cancel
    if params[:commit] == t('dri.views.objects.buttons.cancel')
      if params[:id]
        redirect_to controller: 'my_collections', action: 'show', id: params[:id]
      else
        redirect_to controller: 'workspace', action: 'index'
      end
    end
  end

  def index
    query = "_query_:\"{!join from=id to=ancestor_id_ssim}manager_access_person_ssim:#{current_user.email}\""
    query += " OR manager_access_person_ssim:#{current_user.email}"

    fq = ["+is_collection_ssi:true"]

    if params[:governing].present?
      fq << "+#{Solr::SchemaFields.searchable_symbol('isGovernedBy')}:#{params[:governing]}"
    end

    solr_query = Solr::Query.new(query, 100, { fq: fq })
    collections = results_to_hash(solr_query)

    respond_to do |format|
      format.json { render(json: collections) }
    end
  end

  # Creates a new model.
  #
  def new
    @object = DRI::DigitalObject.with_standard :qdc

    # configure default permissions
    @object.apply_depositor_metadata(current_user.to_s)
    @object.manager_users_string = current_user.to_s
    @object.discover_groups_string = 'public'
    @object.read_groups_string = 'public'
    @object.master_file_access = 'private'
    @object.title = ['']
    @object.description = ['']
    @object.creator = ['']
    @object.creation_date = ['']
    @object.rights = ['']
    @object.type = ['Collection']

    supported_licences

    respond_to do |format|
      format.html
    end
  end

  # Edits an existing model.
  #
  def edit
    enforce_permissions!('manage_collection', params[:id])
    @object = retrieve_object!(params[:id])

    @institutes = Institute.all
    @inst = Institute.new

    @collection_institutes = Institute.where(name: @object.institute.flatten).to_a
    @depositing_institute = @object.depositing_institute.present? ? Institute.find_by(name: @object.depositing_institute) : nil

    supported_licences

    if @object.published? && @object.doi.present?
      flash[:alert] = "#{t('dri.flash.alert.doi_published_warning')}".html_safe
    end

    respond_to do |format|
      format.html
    end
  end

  def lock
    raise Blacklight::AccessControls::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless current_user.is_admin?

    @object = retrieve_object!(params[:id])
    raise DRI::Exceptions::BadRequest unless @object.collection?

    if request.post?
      CollectionLock.create(collection_id: @object.root_collection.first)
    elsif request.delete?
      CollectionLock.delete_all("collection_id = '#{@object.root_collection.first}'")
    end

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.updated', item: params[:id])
      format.html  { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    enforce_permissions!('manage_collection', params[:id])

    @object = retrieve_object!(params[:id])

    # If a cover image was uploaded, remove it from the params hash
    cover_image = params[:digital_object].delete(:cover_image)

    @institutes = Institute.all
    @inst = Institute.new

    supported_licences

    @object.assign_attributes(update_params)
    unless @object.valid?
      flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
      render :edit
      return
    end

    DRI::DigitalObject.transaction do
      @object.increment_version
      if doi
        doi.update_metadata(params[:digital_object].select { |key, _value| doi.metadata_fields.include?(key) })
        new_doi_if_required(@object, doi, 'metadata updated')
      end

      respond_to do |format|
        begin
          @object.index_needs_update = false

          if @object.save && @object.update_index
            if cover_image.present?
              flash[:error] = t('dri.flash.error.cover_image_not_saved') unless Storage::CoverImages.validate_and_store(cover_image, @object)
            end

             # Do the preservation actions
            preservation = Preservation::Preservator.new(@object)
            preservation.preserve(['descMetadata'])

            record_version_committer(@object, current_user)
            mint_or_update_doi(@object, doi) if doi

            flash[:notice] = t('dri.flash.notice.updated', item: params[:id])
            format.html  { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
          else
            after_update_failure
            raise ActiveRecord::Rollback
          end
        rescue RSolr::Error::Http
          after_update_failure
          raise ActiveRecord::Rollback
        end
      end
    end
  end

  # Updates the cover image of an existing model.
  #
  def add_cover_image
    enforce_permissions!('manage_collection', params[:id])

    @object = retrieve_object!(params[:id])

    if params[:digital_object].present? && [:cover_image].present?
      cover_image = params[:digital_object][:cover_image]
    else
      raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.file_not_found')
    end

    @object.increment_version

    if cover_image.present?
      saved = Storage::CoverImages.validate_and_store(cover_image, @object)
    end

    if saved
      record_version_committer(@object, current_user)

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve
    end

    respond_to do |format|
      if saved
        flash[:notice] = t('dri.flash.notice.updated', item: params[:id])
      else
        flash[:error] = t('dri.flash.error.cover_image_not_saved')
      end
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
    end
  end

  def cover
    enforce_permissions!('show_digital_object', params[:id])

    object = SolrDocument.find(params[:id])
    raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') + " ID: #{params[:id]}" if object.blank?

    cover_url = object.cover_image
    raise DRI::Exceptions::NotFound if cover_url.blank?

    if cover_url =~ /\A#{URI.regexp(['http', 'https'])}\z/
      cover_uri = URI.parse(cover_url)
      redirect_to cover_uri.to_s
      return
    end

    uri = URI.parse(cover_url)
    cover_name = File.basename(uri.path)

    storage = StorageService.new
    cover_file = storage.surrogate_url(object.id, cover_name)
    raise DRI::Exceptions::NotFound unless cover_file

    response.headers['Accept-Ranges'] = 'bytes'
    response.headers['Content-Length'] = File.size(cover_file).to_s
    send_file cover_file, { type: MIME::Types.type_for(cover_name).first.content_type, disposition: 'inline' }
  end

  # Updates the licence.
  #
  def set_licence
    enforce_permissions!('manage_collection', params[:id])

    super
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    created = params[:metadata_file].present? ? create_from_xml : create_from_form
    unless created
      if params[:metadata_file].present?
        after_create_failure(DRI::Exceptions::BadRequest)
      else
        render :new
        return
      end
    end

    # If a cover image was uploaded, remove it from the params hash
    cover_image = params[:digital_object]&.delete(:cover_image)

    unless @object.valid?
      flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
      if params[:metadata_file].present?
        after_create_failure(DRI::Exceptions::BadRequest)
      else
        render :new
        return
      end
    end

    if @object.save
      if cover_image.present?
        unless Storage::CoverImages.validate_and_store(cover_image, @object)
          flash[:error] = t('dri.flash.error.cover_image_not_saved')
        end
      end
      # We have to create a default reader group
      create_reader_group

      record_version_committer(@object, current_user)

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(['descMetadata'])

      respond_to do |format|
        format.html do
          flash[:notice] = t('dri.flash.notice.collection_created')
          redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id
        end
        format.json do
          @response = {}
          @response[:id] = @object.alternate_id
          @response[:title] = @object.title
          @response[:description] = @object.description
          render(json: @response, status: :created)
        end
      end

      return
    end

    respond_to do |format|
      format.html do
        flash[:alert] = t('dri.flash.error.unable_to_persist')
        render :new
        return
      end
      format.json do
        response = {}
        response[:error] = t('dri.flash.error.unable_to_persist')
        render json: response, status: 500
      end
    end
  end

  def destroy
    enforce_permissions!('manage_collection', params[:id])

    @object = retrieve_object!(params[:id])

    if current_user.is_admin? || ((can? :manage_collection, @object) && @object.status == 'draft')
      begin
        delete_collection
        flash[:notice] = t('dri.flash.notice.collection_deleted')
      rescue DRI::Exceptions::ResqueError => e
        flash[:error] = t('dri.flash.alert.error_deleting_collection', error: e.message)
        redirect_to :back
        return
      end
    else
      raise Blacklight::AccessControls::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '')
    end

    respond_to do |format|
      format.html { redirect_to controller: 'workspace', action: 'index' }
    end
  end

  def review
    enforce_permissions!('manage_collection', params[:id])
    @object = retrieve_object!(params[:id])

    return if request.get?

    raise DRI::Exceptions::BadRequest unless @object.collection?

    if params[:apply_all].present? && params[:apply_all] == 'yes'
      review_all unless @object.governed_items.blank?
    end

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
      format.json do
        response = { id: @object.alternate_id, status: @object.status }
        response[:warning] = @warnings if @warnings

        render json: response, status: :accepted
      end
    end
  end

  def publish
    enforce_permissions!('manage_collection', params[:id])
    @object = retrieve_object!(params[:id])

    raise DRI::Exceptions::BadRequest unless @object.collection?

    begin
      publish_collection
      flash[:notice] = t('dri.flash.notice.collection_publishing')
    rescue Exception => e
      flash[:alert] = t('dri.flash.alert.error_publishing_collection', error: e.message)
      @warnings = t('dri.flash.alert.error_publishing_collection', error: e.message)
    end

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
      format.json do
        response = { id: @object.alternate_id, status: @object.status }
        response[:warning] = @warnings if @warnings

        render json: response, status: :accepted
      end
    end
  end

  private

    def after_update_exception(exception)
      respond_with_exception(exception)
    end

    def after_update_failure
      flash[:alert] = t('dri.flash.error.unable_to_persist')
      render :new
    end

    def respond_with_exception(exception)
      respond_to do |format|
        format.html do
          raise exception
        end
        format.json do
          raise exception
        end
      end
    end

    # Create a collection with the web form
    #
    def create_from_form
      @object = DRI::DigitalObject.with_standard :qdc

      @object.type = ['Collection'] if @object.type.nil?
      @object.type.push('Collection') unless @object.type.include?('Collection')

      supported_licences

      @object.assign_attributes(create_params)

      # depositor is not submitted as part of the form
      @object.depositor = current_user.to_s

      unless valid_root_permissions?
        flash[:alert] = t('dri.flash.error.not_created')
        return false
      end

      true
    end

    # Create a collection from an uploaded XML file.
    #
    def create_from_xml
      unless params[:metadata_file].present?
        flash[:notice] = t('dri.flash.notice.specify_valid_file')
        @error = t('dri.flash.notice.specify_valid_file')
        return false
      end

      xml_ds = XmlDatastream.new
      begin
        xml_ds.load_xml(params[:metadata_file])
      rescue DRI::Exceptions::InvalidXML
        flash[:notice] = t('dri.flash.notice.specify_valid_file')
        @error = t('dri.flash.notice.specify_valid_file')
        return false
      rescue DRI::Exceptions::ValidationErrors => e
        flash[:notice] = e.message
        @error = e.message
        return false
      end

      if xml_ds.metadata_standard.nil?
        flash[:notice] = t('dri.flash.notice.specify_valid_file')
        @error = t('dri.flash.notice.specify_valid_file')
        return false
      end

      @object = DRI::DigitalObject.with_standard xml_ds.metadata_standard
      @object.update_metadata xml_ds.xml
      checksum_metadata(@object)
      warn_if_has_duplicates(@object)

      if @object.descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescriptionComponent)
        flash[:notice] = t('dri.flash.notice.specify_valid_file')
        @error = t('dri.flash.notice.specify_valid_file')
        return false
      end

      unless @object.collection?
        flash[:notice] = t('dri.flash.notice.specify_collection')
        @error = t('dri.flash.notice.specify_collection')
        return false
      end

      @object.apply_depositor_metadata(current_user.to_s)
      @object.manager_users_string = current_user.to_s
      @object.discover_groups_string = 'public'
      @object.read_groups_string = 'public'
      @object.master_file_access = 'private'

      @object.ingest_files_from_metadata = params[:ingest_files] if params[:ingest_files].present?

      true
    end

    def create_reader_group
      @group = UserGroup::Group.new(
        name: reader_group_name,
        description: "Default Reader group for collection #{@object.alternate_id}"
      )
      @group.reader_group = true
      @group.save
      @group
    end

    def reader_group_name
      @object.alternate_id
    end

    def redirect_url(cover_url)
      if cover_url =~ /\A#{URI.regexp(['http', 'https'])}\z/
        cover_uri = force_https(cover_url)
        redirect_to cover_uri.to_s
        return true
      end

      false
    end

    def force_https(cover_url)
      cover_uri = URI.parse(cover_url)
      cover_uri.scheme = 'https' if Rails.env == 'production'

      cover_uri
    end

    def results_to_hash(solr_query)
      collections = []

      while solr_query.has_more?
        objects = solr_query.pop
        objects.each do |object|
          collection = {}
          collection[:id] = object['id']
          collection[:collection_title] = object[
            Solr::SchemaFields.searchable_string('title')
          ]
           governing = object[Solr::SchemaFields.searchable_symbol(
            'isGovernedBy')]
            collection[:governing_collection] = governing.present? ? governing.first : 'root'

          collections.push(collection)
        end
      end

      collections.group_by {|c| c[:governing_collection]}
    end

    def review_all
      job_id = ReviewCollectionJob.create(
        'collection_id' => @object.alternate_id,
        'user_id' => current_user.id
      )
      UserBackgroundTask.create(
        user_id: current_user.id,
        job: job_id
      )

      flash[:notice] = t('dri.flash.notice.collection_objects_review')
    rescue Exception => e
      logger.error "Unable to submit status job: #{e.message}"
      flash[:alert] = t('dri.flash.alert.error_review_job', error: e.message)
      @warnings = t('dri.flash.alert.error_review_job', error: e.message)
    end

    def delete_collection
      DRI.queue.push(DeleteCollectionJob.new(@object.alternate_id))
    rescue Exception => e
      logger.error "Unable to delete collection: #{e.message}"
      raise DRI::Exceptions::ResqueError, e.message
    end

    def publish_collection
      job_id = PublishCollectionJob.create(
        'collection_id' => @object.alternate_id,
        'user_id' => current_user.id
      )
      UserBackgroundTask.create(
        user_id: current_user.id,
        job: job_id
      )
    rescue Exception => e
      logger.error "Unable to submit publish job: #{e.message}"
      raise DRI::Exceptions::ResqueError
    end

    def respond_with_exception(exception)
      respond_to do |format|
        format.html { raise exception }
        format.json { render json: exception.message, status: :bad_request }
      end
    end

    def valid_root_permissions?
      !((params[:digital_object][:manager_users_string].blank? && params[:digital_object][:edit_users_string].blank?))
    end
end
