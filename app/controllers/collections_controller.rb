# Controller for the Collection model
#
require 'storage/cover_images'
require 'validators'

class CollectionsController < BaseObjectsController

  # Creates a new model.
  #
  def new
    enforce_permissions!("create", DRI::Batch)
    @object = DRI::Batch.with_standard :qdc

    # configure default permissions
    @object.apply_depositor_metadata(current_user.to_s)
    @object.manager_users_string=current_user.to_s
    @object.discover_groups_string="public"
    @object.read_groups_string="public"
    @object.master_file_access="private"
    @object.object_type = ["Collection"]
    @object.title = [""]
    @object.description = [""]
    @object.creator = [""]
    @object.creation_date = [""]
    @object.publisher = [""]
    @object.rights = [""]
    @object.type = [ "Collection" ]

    supported_licences()

    respond_to do |format|
      format.html
    end
  end

  # Edits an existing model.
  #
  def edit
    enforce_permissions!("manage_collection",params[:id])
    @object = retrieve_object!(params[:id])

    @institutes = Institute.all
    @inst = Institute.new

    @collection_institutes = InstituteHelpers.get_collection_institutes(@object)
    @depositing_institute = InstituteHelpers.get_depositing_institute(@object)

    supported_licences()

    respond_to do |format|
      format.html
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    params[:batch][:read_users_string] = params[:batch][:read_users_string].to_s.downcase
    params[:batch][:edit_users_string] = params[:batch][:edit_users_string].to_s.downcase
    params[:batch][:manager_users_string] = params[:batch][:manager_users_string].to_s.downcase

    update_object_permission_check(params[:batch][:manager_groups_string],params[:batch][:manager_users_string], params[:id])

    @object = retrieve_object!(params[:id])

    # If a cover image was uploaded, remove it from the params hash
    cover_image = params[:batch].delete(:cover_image)

    #For sub collections will have to set a governing_collection_id
    #Create a sub collections controller?

    @institutes = Institute.all
    @inst = Institute.new

    supported_licences()

    update_doi = doi_update_required?

    if valid_permissions?
      updated = @object.update_attributes(update_params)

      if updated
        if cover_image.present?
          flash[:error] = t('dri.flash.error.cover_image_not_saved') unless Storage::CoverImages.validate(cover_image, @object)
        end
      else
        flash[:alert] = t('dri.flash.alert.invalid_object', :error => @object.errors.full_messages.inspect)
      end
    else
      flash[:alert] = t('dri.flash.error.not_updated', :item => params[:id])
    end

    #purge params from update action
    purge_params

    respond_to do |format|
      if updated

        actor.version_and_record_committer
        actor.mint_doi("metadata update") if update_doi

        flash[:notice] = t('dri.flash.notice.updated', :item => params[:id])
        format.html  { redirect_to :controller => "catalog", :action => "show", :id => @object.id }
      else
        format.html  { render :action => "edit" }
      end
    end
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    created = params[:metadata_file].present? ? create_from_xml : create_from_form
     
    unless created
      respond_with_exception(Exceptions::BadRequest.new(t('dri.views.exceptions.invalid_metadata_input')))
      return
    end

    if @object.valid? && @object.save
      # We have to create a default reader group
      create_reader_group

      actor.version_and_record_committer

      respond_to do |format|
        format.html { flash[:notice] = t('dri.flash.notice.collection_created')
        redirect_to :controller => "catalog", :action => "show", :id => @object.id }
        format.json {
          @response = {}
          @response[:id] = @object.id
          @response[:title] = @object.title
          @response[:description] = @object.description
          render(:json => @response, :status => :created)
        }
      end
    else
      respond_to do |format|
        format.html {
          flash[:alert] = t('dri.flash.alert.invalid_object', :error => @object.errors.full_messages.inspect)
          raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata_input')
        }
        format.json {
          raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata_input')
          render :json => @object.errors.messages.values.to_s
        }
      end
    end
  end

  def destroy
    enforce_permissions!("manage_collection",params[:id])

    @object = retrieve_object!(params[:id])

    if current_user.is_admin? || ((can? :manage_collection, @object) && @object.status == "draft")
      begin
        delete_collection
        flash[:notice] = t('dri.flash.notice.collection_deleted')
      rescue Exception => e
        flash[:alert] = t('dri.flash.alert.error_deleting_collection', :error => e.message)
      end
    else
      raise Hydra::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, "")
    end

    respond_to do |format|
      format.html { redirect_to :controller => "catalog", :action => "index" }
    end
  end

  def review
    enforce_permissions!("edit",params[:id])

    @object = retrieve_object!(params[:id])

    return if request.get?

    raise Exceptions::BadRequest unless @object.is_collection?

    unless @object.status.eql?("reviewed")
      @object.status = "reviewed"
      @object.save
    end

    if params[:apply_all].present? && params[:apply_all].eql?("yes")
      begin
        Sufia.queue.push(ReviewCollectionJob.new(@object.id)) unless @object.governed_items.blank?
      rescue Exception => e
        logger.error "Unable to submit status job: #{e.message}"
        flash[:alert] = t('dri.flash.alert.error_review_job', :error => e.message)
        @warnings = t('dri.flash.alert.error_review_job', :error => e.message)
      end
    end

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.metadata_updated')
      format.html  { redirect_to :controller => "catalog", :action => "show", :id => @object.id }
      format.json {
        if @warnings
          response = { :warning => @warnings, :id => @object.id, :status => @object.status }
        else
          response = { :id => @object.id, :status => @object.status }
        end
        render :json => response, :status => :accepted }
    end
  end

  def publish
    enforce_permissions!("manage_collection", params[:id])

    @object = retrieve_object!(params[:id])

    raise Exceptions::BadRequest unless @object.is_collection?

    begin
      publish_collection
      flash[:notice] = t('dri.flash.notice.collection_publishing')
    rescue Exception => e
      flash[:alert] = t('dri.flash.alert.error_publishing_collection', :error => e.message)
      @warnings = t('dri.flash.alert.error_publishing_collection', :error => e.message)
    end

    respond_to do |format|
      format.html  { redirect_to :controller => "catalog", :action => "show", :id => @object.id }
      format.json {
          if @warnings
            response = { :warning => @warnings, :id => @object.id, :status => @object.status }
          else
            response = { :id => @object.id, :status => @object.status }
          end
          render :json => response, :status => :accepted }
    end
  end

  private

  # Create a collection with the web form
  #
  def create_from_form
    enforce_permissions!("create", DRI::Batch)

    @object = DRI::Batch.with_standard :qdc

    @object.type = ["Collection"] if @object.type == nil
    @object.type.push("Collection") unless @object.type.include?("Collection")

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
    enforce_permissions!("create", DRI::Batch)

    unless params[:metadata_file].present?
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
      return false
    end

    xml = MetadataHelpers.load_xml(params[:metadata_file])
    standard = MetadataHelpers.get_metadata_standard_from_xml xml

    if standard.nil?
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
      return false
    end

    @object = DRI::Batch.with_standard standard

    MetadataHelpers.set_metadata_datastream(@object, xml)
    MetadataHelpers.checksum_metadata(@object)
    warn_if_duplicates

    if @object.descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescriptionComponent)
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
      return false
    end

    unless @object.is_collection?
      flash[:notice] = "Metadata file does not specify that the object is a collection."
      return false
    end

    @object.apply_depositor_metadata(current_user.to_s)
    @object.manager_users_string=current_user.to_s
    @object.discover_groups_string="public"
    @object.read_groups_string="public"
    @object.master_file_access="private"

    @object.ingest_files_from_metadata = params[:ingest_files] if params[:ingest_files].present?

    true
  end

  private

  def valid_permissions?
    if ((params[:batch][:read_groups_string].blank? && params[:batch][:read_users_string].blank?) ||
        (params[:batch][:manager_users_string].blank? && params[:batch][:edit_users_string].blank?))
      false
    else
      true
    end
  end

  def create_reader_group
    @group = UserGroup::Group.new(:name => reader_group_name, :description => "Default Reader group for collection #{@object.id}")
    @group.reader_group = true
    @group.save
    @group
  end

  def reader_group_name
    @object.id
  end

  def delete_collection
    begin
      Sufia.queue.push(DeleteCollectionJob.new(@object.id))
    rescue Exception => e
      logger.error "Unable to delete collection: #{e.message}"
      raise Exceptions::ResqueError
    end
  end

  def publish_collection
    begin
      Sufia.queue.push(PublishJob.new(@object.id))
    rescue Exception => e
      logger.error "Unable to submit publish job: #{e.message}"
      raise Exceptions::ResqueError
    end
  end

  def respond_with_exception exception
    respond_to do |format|
        format.html {
          raise exception
        }
        format.json {
          render :json => exception.message, :status => :bad_request
        }
      end
  end

end

