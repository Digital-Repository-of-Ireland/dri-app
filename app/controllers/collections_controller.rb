# Controller for the Collection model
#
require 'storage/s3_interface'
require 'storage/cover_images'
require 'validators'
require 'institute_helpers'
require 'doi/doi'

class CollectionsController < CatalogController

  include UserGroup::SolrAccessControls

  before_filter :authenticate_user!, :only => [:create, :new, :edit, :update]

  # Creates a new model.
  #
  def new
    enforce_permissions!("create", Batch)
    @object = Batch.new

    # configure default permissions
    @object.apply_depositor_metadata(current_user.to_s)
    @object.manager_users_string=current_user.to_s
    @object.discover_groups_string="public"
    @object.read_groups_string="public"
    @object.private_metadata="0"
    @object.master_file="0"
    @object.object_type = ["Collection"]
    @object.title = [""]
    @object.description = [""]
    @object.creator = [""]
    @object.creation_date = [""]
    @object.publisher = [""]
    @object.rights = [""]
    @object.type = [ "Collection" ]

    @licences = {}
    Licence.find(:all).each do |licence|
      @licences["#{licence['name']}: #{licence[:description]}"] = licence['name']
    end

    respond_to do |format|
      format.html
    end
  end

  # Edits an existing model.
  #
  def edit
    enforce_permissions!("edit",params[:id])
    @object = retrieve_object!(params[:id])

    @institutes = Institute.find(:all)
    @inst = Institute.new

    @collection_institutes = InstituteHelpers.get_collection_institutes(@object)

    @licences = {}
    Licence.find(:all).each do |licence|
      @licences["#{licence['name']}: #{licence[:description]}"] = licence['name']
    end

    respond_to do |format|
      format.html
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    update_object_permission_check(params[:batch][:manager_groups_string],params[:batch][:manager_users_string], params[:id])

    @object = retrieve_object!(params[:id])

    # If a cover image was uploaded, remove it from the params hash
    cover_image = params[:batch].delete(:cover_image)

    #For sub collections will have to set a governing_collection_id
    #Create a sub collections controller?

    @institutes = Institute.find(:all)
    @inst = Institute.new

    @licences = {}
      Licence.find(:all).each do |licence|
      @licences["#{licence['name']}: #{licence[:description]}"] = licence['name']
    end

    set_access_permissions(:batch, true)

    if !valid_permissions?
      flash[:error] = t('dri.flash.error.not_updated', :item => params[:id])
    else
      @object.update_attributes(params[:batch])

      DOI.mint_doi( @object )

      Storage::CoverImages.validate(cover_image, @object)

      #Apply private_metadata & properties to each DO/Subcollection within this collection
      flash[:notice] = t('dri.flash.notice.updated', :item => params[:id])
    end

    respond_to do |format|
      format.html  { render :action => "edit" }
    end
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    enforce_permissions!("create", Batch)

    set_access_permissions(:batch, true)

    @collection = Batch.new
    if @collection.type == nil
      @collection.type = ["Collection"]
    end

    if !@collection.type.include?("Collection")
      @collection.type.push("Collection")
    end

    @licences = {}
      Licence.find(:all).each do |licence|
      @licences["#{licence['name']}: #{licence[:description]}"] = licence['name']
    end

    # If a cover image was uploaded, remove it from the params hash
    cover_image = params[:batch].delete(:cover_image)

    @collection.update_attributes(params[:batch])


    # depositor is not submitted as part of the form
    @collection.depositor = current_user.to_s

    if !valid_permissions?
      flash[:alert] = t('dri.flash.error.not_created')
      @object = @collection
      render :action => :new
      return
    end

    # We need to save to get a pid at this point
    if @collection.save
      DOI.mint_doi( @collection )

      # We have to create a default reader group
      create_reader_group

      Storage::CoverImages.validate(cover_image, @collection)
    end

    respond_to do |format|
      if @collection.save

        format.html { flash[:notice] = t('dri.flash.notice.collection_created')
            redirect_to :controller => "catalog", :action => "show", :id => @collection.id }
        format.json {
          @response = {}
          @response[:id] = @collection.pid
          @response[:title] = @collection.title
          @response[:description] = @collection.description
          render(:json => @response, :status => :created)
        }
      else
        format.html {
          flash[:alert] = @collection.errors.messages.values.to_s
          render :action => :new
        }
        format.json { render(:json => @collection.errors.messages.values.to_s) }
        raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_collection')
      end
    end
  end

  def destroy
    enforce_permissions!("edit",params[:id])

    if current_user.is_admin?
      @collection = retrieve_object!(params[:id])

      @collection.governed_items.each do |object|
        begin
          # this makes a connection to s3, should really test if connection is available somewhere else
          delete_files(object)
        rescue Exception => e
            puts 'cannot delete files'
        end
        object.delete
      end
      @collection.reload
      @collection.delete
    end

    respond_to do |format|
      format.html { flash[:notice] = t('dri.flash.notice.collection_deleted')
      redirect_to :controller => "catalog", :action => "index" }
    end

  end

  private

    def valid_permissions?
      if (
       #(params[:batch][:master_file].blank? || params[:batch][:master_file]==UserGroup::Permissions::INHERIT_MASTERFILE) ||
       (params[:batch][:read_groups_string].blank? && params[:batch][:read_users_string].blank?) ||
       (params[:batch][:manager_users_string].blank? && params[:batch][:edit_users_string].blank?))
         return false
      else
         return true
      end
    end

    def delete_files(object)
      local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d",
                                                                { :f => object.id, :d => 'content' } ],
                                            :order => "version DESC")
      local_file_info.each { |file| file.destroy }
      FileUtils.remove_dir(Rails.root.join(Settings.dri.files).join(object.id), :force => true)

      storage = Storage::S3Interface.new
      storage.delete_bucket(object.id.sub('dri:', ''))
      storage.close
    end

    def create_reader_group
      @group = UserGroup::Group.new(:name => reader_group_name, :description => "Default Reader group for collection #{@collection.id}")
      @group.save
      @group
    end

    def reader_group_name
      @collection.id.sub(':', '_')
    end

end

