# Controller for the Collection model
#
require 'storage/cover_images'
require 'validators'

class CollectionsController < BaseObjectsController
  include Hydra::AccessControlsEnforcement
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
    query = "_query_:\"{!join from=id to=ancestor_id_sim}manager_access_person_ssim:#{current_user.email}\""
    query += " OR manager_access_person_ssim:#{current_user.email}"

    fq = ["+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true"]

    if params[:governing].present?
      fq << "+#{ActiveFedora.index_field_mapper.solr_name('isGovernedBy', :stored_searchable, type: :symbol)}:#{params[:governing]}"
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
    @object = DRI::Batch.with_standard :qdc

    # configure default permissions
    @object.apply_depositor_metadata(current_user.to_s)
    @object.manager_users_string = current_user.to_s
    @object.discover_groups_string = 'public'
    @object.read_groups_string = 'public'
    @object.master_file_access = 'private'
    @object.object_type = ['Collection']
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

    @collection_institutes = Institute.where(name: @object.institute).to_a
    @depositing_institute = @object.depositing_institute.present? ? Institute.find_by(name: @object.depositing_institute) : nil

    supported_licences

    respond_to do |format|
      format.html
    end
  end

  def lock
    raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless current_user.is_admin?

    @object = retrieve_object!(params[:id])
    raise DRI::Exceptions::BadRequest unless @object.collection?

    if request.post?
      CollectionLock.create(collection_id: @object.root_collection.first)
    elsif request.delete?
      CollectionLock.delete_all("collection_id = '#{@object.root_collection.first}'")
    end

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.updated', item: params[:id])
      format.html  { redirect_to controller: 'my_collections', action: 'show', id: @object.id }
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    enforce_permissions!('manage_collection', params[:id])

    @object = retrieve_object!(params[:id])

    # If a cover image was uploaded, remove it from the params hash
    cover_image = params[:batch].delete(:cover_image)

    @institutes = Institute.all
    @inst = Institute.new

    supported_licences

    doi.update_metadata(params[:batch].select { |key, _value| doi.metadata_fields.include?(key) }) if doi

    @object.object_version ||= '1'
    @object.increment_version

    updated = @object.update_attributes(update_params)

    if updated
      if cover_image.present?
        flash[:error] = t('dri.flash.error.cover_image_not_saved') unless Storage::CoverImages.validate_and_store(cover_image, @object)
      end

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(false, false, ['descMetadata','properties'])

    else
      flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
    end

    # purge params from update action
    purge_params

    respond_to do |format|
      if updated
        version_and_record_committer(@object, current_user)
        update_doi(@object, doi, "metadata update") if doi && doi.changed?

        flash[:notice] = t('dri.flash.notice.updated', item: params[:id])
        format.html  { redirect_to controller: 'my_collections', action: 'show', id: @object.id }
      else
        format.html  { render action: 'edit' }
      end
    end
  end

  # Updates the cover image of an existing model.
  #
  def add_cover_image
    enforce_permissions!('manage_collection', params[:id])

    @object = retrieve_object!(params[:id])

    if params[:batch].present? && [:cover_image].present?
      cover_image = params[:batch][:cover_image]
    else
      raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.file_not_found')
    end

    @object.object_version ||= '1'
    @object.increment_version

    if cover_image.present?
      saved = Storage::CoverImages.validate_and_store(cover_image, @object)
    end

    if saved
      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(false, false, ['properties'])
    end

    # purge params from update action
    purge_params

    respond_to do |format|
      if saved
        flash[:notice] = t('dri.flash.notice.updated', item: params[:id])
      else
        flash[:error] = t('dri.flash.error.cover_image_not_saved')
      end
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.id }
    end
  end

  def cover
    enforce_permissions!('show_digital_object', params[:id])

    solr_result = ActiveFedora::SolrService.query(
      ActiveFedora::SolrQueryBuilder.construct_query_for_ids([params[:id]])
    )
    raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') + " ID: #{params[:id]}" if solr_result.blank?

    object = SolrDocument.new(solr_result.first)

    cover_url = object.cover_image
    raise DRI::Exceptions::NotFound if cover_url.blank?
    if cover_url =~ /\A#{URI.regexp(['http', 'https'])}\z/
      cover_uri = URI.parse(cover_url)
      #cover_uri.scheme = 'https'
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

    if created && (@object.valid? && @object.save)
      # We have to create a default reader group
      create_reader_group

      version_and_record_committer(@object, current_user)

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(true, true, ['descMetadata','properties'])

      respond_to do |format|
        format.html do
          flash[:notice] = t('dri.flash.notice.collection_created')
          redirect_to controller: 'my_collections', action: 'show', id: @object.id
        end
        format.json do
          @response = {}
          @response[:id] = @object.id
          @response[:title] = @object.title
          @response[:description] = @object.description
          render(json: @response, status: :created)
        end
      end
    else
      respond_to do |format|
        format.html do
          unless @object.nil? || @object.valid?
            flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
          end
          raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata_input')
        end
        format.json do
          unless @object.nil? || @object.valid?
            @error = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
          end
          response = {}
          response[:error] = @error
          render json: response, status: :bad_request
        end
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
      raise Hydra::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '')
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
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.id }
      format.json do
        response = { id: @object.id, status: @object.status }
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
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.id }
      format.json do
        response = { id: @object.id, status: @object.status }
        response[:warning] = @warnings if @warnings

        render json: response, status: :accepted
      end
    end
  end

  private

    # Create a collection with the web form
    #
    def create_from_form
      unless valid_root_permissions?
        flash[:alert] = t('dri.flash.error.not_created')
        return false
      end

      @object = DRI::Batch.with_standard :qdc

      @object.type = ['Collection'] if @object.type.nil?
      @object.type.push('Collection') unless @object.type.include?('Collection')

      supported_licences

      # If a cover image was uploaded, remove it from the params hash
      cover_image = params[:batch].delete(:cover_image)

      @object.update_attributes(create_params)

      # depositor is not submitted as part of the form
      @object.depositor = current_user.to_s

      # We need to save to get a pid at this point
      if @object.save
        if cover_image.present?
          unless Storage::CoverImages.validate_and_store(cover_image, @object)
            flash[:error] = t('dri.flash.error.cover_image_not_saved')
          end
        end
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

      @object = DRI::Batch.with_standard xml_ds.metadata_standard
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
        description: "Default Reader group for collection #{@object.id}"
      )
      @group.reader_group = true
      @group.save
      @group
    end

    def reader_group_name
      @object.id
    end

    def results_to_hash(solr_query)
      collections = []

      while solr_query.has_more?
        objects = solr_query.pop
        objects.each do |object|
          collection = {}
          collection[:id] = object['id']
          collection[:collection_title] = object[
            ActiveFedora.index_field_mapper.solr_name(
            'title', :stored_searchable, type: :string
            )
          ]
           governing = object[
            ActiveFedora.index_field_mapper.solr_name(
            'isGovernedBy', :stored_searchable, type: :symbol
            )]
            collection[:governing_collection] = governing.present? ? governing.first : 'root'

          collections.push(collection)
        end
      end

      collections.group_by {|c| c[:governing_collection]}
    end

    def review_all
      job_id = ReviewCollectionJob.create(
        'collection_id' => @object.id,
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
      DRI.queue.push(DeleteCollectionJob.new(@object.id))
    rescue Exception => e
      logger.error "Unable to delete collection: #{e.message}"
      raise DRI::Exceptions::ResqueError, e.message
    end

    def publish_collection
      job_id = PublishCollectionJob.create(
        'collection_id' => @object.id,
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
      !((params[:batch][:manager_users_string].blank? && params[:batch][:edit_users_string].blank?))
    end
end
