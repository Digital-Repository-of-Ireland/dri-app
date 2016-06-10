# Controller for the Collection model
#
require 'storage/cover_images'
require 'validators'

class CollectionsController < BaseObjectsController
  include Hydra::AccessControlsEnforcement

  before_filter :authenticate_user_from_token!, except: [:cover]
  before_filter :authenticate_user!, except: [:cover]
  before_filter :check_for_cancel, only: [:create, :update, :add_cover_image]
  before_filter :read_only, except: [:index]

  # Was this action canceled by the user?
  def check_for_cancel
    if params[:commit] == t('dri.views.objects.buttons.cancel')
      if params[:id]
        redirect_to controller: 'catalog', action: 'show', id: params[:id]
      else
        redirect_to controller: 'catalog', action: 'index'
      end
    end
  end

  def index
    query = "#{Solrizer.solr_name('manager_access_person', :stored_searchable, type: :symbol)}:#{current_user.email}"

    solr_query = Solr::Query.new(query, 100, 
      {fq: ["+#{ActiveFedora::SolrQueryBuilder.solr_name('is_collection', :facetable, type: :string)}:true",
            "-#{ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"]}
      )

    collections = []

    while solr_query.has_more?
      objects = solr_query.pop
      objects.each do |object|
        collection = {}
        collection[:id] = object['id']
        collection[:collection_title] = object[ActiveFedora::SolrQueryBuilder.solr_name(
          'title', :stored_searchable, type: :string)]
        collections.push(collection)
      end
    end
    
    respond_to do |format|
        format.json {
          render(json: collections.to_json)
        }
      end
  end

  # Creates a new model.
  #
  def new
    enforce_permissions!('create', DRI::Batch)
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
    @object.publisher = ['']
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

    @collection_institutes = Institute.find_collection_institutes(@object.institute)
    @depositing_institute = @object.depositing_institute.present? ? Institute.find_by(name: @object.depositing_institute) : nil

    supported_licences

    respond_to do |format|
      format.html
    end
  end
  
  # Updates the attributes of an existing model.
  #
  def update
    enforce_permissions!('manage_collection', params[:id])

    @object = retrieve_object!(params[:id])

    # If a cover image was uploaded, remove it from the params hash
    cover_image = params[:batch].delete(:cover_image)

    #For sub collections will have to set a governing_collection_id
    #Create a sub collections controller?

    @institutes = Institute.all
    @inst = Institute.new

    supported_licences

    doi.update_metadata(params[:batch].select{ |key, value| doi.metadata_fields.include?(key) }) if doi
        
    updated = @object.update_attributes(update_params)

    if updated
      if cover_image.present?
        flash[:error] = t('dri.flash.error.cover_image_not_saved') unless Storage::CoverImages.validate(cover_image, @object)
      end
    else
      flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
    end
    
    #purge params from update action
    purge_params

    respond_to do |format|
      if updated
        actor.version_and_record_committer
        update_doi(@object, doi, "metadata update") if doi && doi.changed?

        flash[:notice] = t('dri.flash.notice.updated', item: params[:id])
        format.html  { redirect_to controller: 'catalog', action: 'show', id: @object.id }
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

    # If a cover image was uploaded, remove it from the params hash
    cover_image = params[:batch][:cover_image]

    if cover_image.present?
      updated = Storage::CoverImages.validate(cover_image, @object)
    end

    #purge params from update action
    purge_params

    respond_to do |format|
      if updated
        flash[:notice] = t('dri.flash.notice.updated', item: params[:id])
      else
        flash[:error] = t('dri.flash.error.cover_image_not_saved')
      end
      format.html { redirect_to controller: 'catalog', action: 'show', id: @object.id }
    end
  end

  def cover
    enforce_permissions!('show_digital_object', params[:id])

    solr_result = ActiveFedora::SolrService.query(
      ActiveFedora::SolrQueryBuilder.construct_query_for_ids([params[:id]])
    )
    raise Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') + " ID: #{params[:id]}" if solr_result.blank?

    object = SolrDocument.new(solr_result.first)

    cover_url = object.cover_image
    raise Exceptions::NotFound if cover_url.blank?
    if cover_url =~ /\A#{URI::regexp(['http', 'https'])}\z/
      redirect_to cover_url
      return
    end

    uri = URI.parse(cover_url)
    cover_name = File.basename(uri.path)
    
    storage = StorageService.new
    cover_file = storage.surrogate_url(object.id, cover_name)
    raise Exceptions::NotFound unless cover_file

    open(cover_file) do |f|
      send_data f.read, 
        type: MIME::Types.type_for(cover_name).first.content_type, 
        disposition: 'inline'
    end
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

      actor.version_and_record_committer

      respond_to do |format|
        format.html { flash[:notice] = t('dri.flash.notice.collection_created')
                      redirect_to controller: 'catalog', action: 'show', id: @object.id
                    }
        format.json {
          @response = {}
          @response[:id] = @object.id
          @response[:title] = @object.title
          @response[:description] = @object.description
          render(json: @response, status: :created)
        }
      end
    else
      respond_to do |format|
        format.html {
          unless @object.nil? || @object.valid?
            flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
          end
          raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata_input')
        }
        format.json {
          unless @object.nil? || @object.valid?
            @error = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
          end
          response = {}
          response[:error] = @error
          render json: response, status: :bad_request
        }
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
      rescue Exception => e
        flash[:alert] = t('dri.flash.alert.error_deleting_collection', error: e.message)
      end
    else
      raise Hydra::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '')
    end

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'index' }
    end
  end

  def duplicates
    enforce_permissions!('manage_collection', params[:id])

    result = ActiveFedora::SolrService.query("id:#{params[:id]}")
    raise Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') + " ID: #{params[:id]}" if result.blank?

    @object = SolrDocument.new(result.first)

    @response, document_list = @object.duplicates
    @document_list = Kaminari.paginate_array(document_list).page(params[:page]).per(params[:per_page])
  end

  def review
    enforce_permissions!('manage_collection', params[:id])

    @object = retrieve_object!(params[:id])

    return if request.get?

    raise Exceptions::BadRequest unless @object.collection?

    if params[:apply_all].present? && params[:apply_all] == 'yes'
      review_all unless @object.governed_items.blank?
    end

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'show', id: @object.id }
      format.json {
        response = { id: @object.id, status: @object.status }
        response[:warning] = @warnings if @warnings

        render json: response, status: :accepted
      }
    end
  end

  def publish
    enforce_permissions!('manage_collection', params[:id])

    @object = retrieve_object!(params[:id])

    raise Exceptions::BadRequest unless @object.collection?

    begin
      publish_collection
      flash[:notice] = t('dri.flash.notice.collection_publishing')
    rescue Exception => e
      flash[:alert] = t('dri.flash.alert.error_publishing_collection', error: e.message)
      @warnings = t('dri.flash.alert.error_publishing_collection', error: e.message)
    end

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'show', id: @object.id }
      format.json {
        response = { id: @object.id, status: @object.status }
        response[:warning] = @warnings if @warnings

        render json: response, status: :accepted 
      }
    end
  end

  private

  # Create a collection with the web form
  #
  def create_from_form
    enforce_permissions!('create', DRI::Batch)

    @object = DRI::Batch.with_standard :qdc

    @object.type = ['Collection'] if @object.type.nil?
    @object.type.push('Collection') unless @object.type.include?('Collection')

    supported_licences()

    # If a cover image was uploaded, remove it from the params hash
    cover_image = params[:batch].delete(:cover_image)

    @object.update_attributes(create_params)

    # depositor is not submitted as part of the form
    @object.depositor = current_user.to_s

    unless valid_permissions?
      flash[:alert] = t('dri.flash.error.not_created')
      return false
    end

    # We need to save to get a pid at this point
    if @object.save
      if cover_image.present?
        flash[:error] = t('dri.flash.error.cover_image_not_saved') unless Storage::CoverImages.validate(cover_image, @object)
      end
    end

    true
  end

  # Create a collection from an uploaded XML file.
  #
  def create_from_xml
    enforce_permissions!('create', DRI::Batch)

    unless params[:metadata_file].present?
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
      @error = t('dri.flash.notice.specify_valid_file')
      return false
    end

    begin
      xml = MetadataHelpers.load_xml(params[:metadata_file])
    rescue Exceptions::InvalidXML
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
      @error = t('dri.flash.notice.specify_valid_file')
      return false
    rescue Exceptions::ValidationErrors => e
      flash[:notice] = e.message
      @error = e.message
      return false
    end
    
    standard = MetadataHelpers.get_metadata_standard_from_xml xml

    if standard.nil?
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
      @error = t('dri.flash.notice.specify_valid_file')
      return false
    end

    @object = DRI::Batch.with_standard standard
    MetadataHelpers.set_metadata_datastream(@object, xml)
    MetadataHelpers.checksum_metadata(@object)
    warn_if_duplicates

    if @object.descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescriptionComponent)
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
      @error = t('dri.flash.notice.specify_valid_file')
      return false
    end

    unless @object.collection?
      flash[:notice] = "Metadata file does not specify that the object is a collection."
      @error = "Metadata file does not specify that the object is a collection."
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

  private

  def create_reader_group
    @group = UserGroup::Group.new(name: reader_group_name, description: "Default Reader group for collection #{@object.id}")
    @group.reader_group = true
    @group.save
    @group
  end

  def reader_group_name
    @object.id
  end

  def review_all
    Sufia.queue.push(ReviewCollectionJob.new(@object.id))
    flash[:notice] = t('dri.flash.notice.collection_objects_review')
  rescue Exception => e
    logger.error "Unable to submit status job: #{e.message}"
    flash[:alert] = t('dri.flash.alert.error_review_job', error: e.message)
    @warnings = t('dri.flash.alert.error_review_job', error: e.message)
  end

  def delete_collection
    Sufia.queue.push(DeleteCollectionJob.new(@object.id))
  rescue Exception => e
    logger.error "Unable to delete collection: #{e.message}"
    raise Exceptions::ResqueError
  end
   
  def publish_collection
    Sufia.queue.push(PublishJob.new(@object.id))
  rescue Exception => e
    logger.error "Unable to submit publish job: #{e.message}"
    raise Exceptions::ResqueError
  end

  def respond_with_exception(exception)
    respond_to do |format|
        format.html {
          raise exception
        }
        format.json {
          render json: exception.message, status: :bad_request
        }
      end
  end

  def valid_permissions?
    if (@object.governing_collection_id.blank? &&
       ((params[:batch][:read_groups_string].blank? && params[:batch][:read_users_string].blank?) ||
       (params[:batch][:manager_users_string].blank? && params[:batch][:edit_users_string].blank?)))
      false
    else
      true
    end
  end
end

