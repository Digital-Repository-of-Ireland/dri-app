# Controller for the Collection model
#
require 'storage/s3_interface'

class CollectionsController < CatalogController

  before_filter :authenticate_user!, :only => [:create, :new, :edit, :update]

  # Shows list of user's collections
  #
  def index
    @collections = get_collections

    if current_user
      @collections.select! { |c| (can?(:edit, c[:id]) || can?(:create_do, c[:id])) } unless current_user.is_admin?
    end

    @collection_counts = {}

    @collections.each do |collection|
      @collection_counts[collection[:id]] = count_items_in_collection collection[:id]
    end

    respond_to do |format|
      format.html
      format.json {
        collectionhash = []
        @collections.each do |collection|
          collectionhash << { :id => collection[:id],
                               :title => collection[:title],
                               :description => collection[:description],
                               :publisher => collection[:publisher],
                               :objectcount => collection_counts[collection[:id]] }.to_json
        end
        @collections = collectionhash
      }
    end
  end

  # Creates a new model.
  #
  def new
    enforce_permissions!("create", DRI::Model::Collection)
    @collection = DRI::Model::Collection.new

    # configure default permissions
    @collection.apply_depositor_metadata(current_user.to_s)
    @collection.manager_users_string=current_user.to_s
    @collection.discover_groups_string="public"
    @collection.read_groups_string="public"
    @collection.private_metadata="0"
    @collection.master_file="1"

    respond_to do |format|
      format.html
    end
  end

  # Edits an existing model.
  #
  def edit
    enforce_permissions!("edit",params[:id])
    @collection = retrieve_object!(params[:id])

    respond_to do |format|
      format.html
    end
  end

  # Retrieves an existing model.
  #
  def show
    enforce_permissions!("show",params[:id])

    @collection = retrieve_object!(params[:id])
    @children = get_items_in_collection params[:id]

    respond_to do |format|
      format.html
      format.json  {
        @response = {}
        @response[:id] = @collection.pid
        @response[:title] = @collection.title
        @response[:description] = @collection.description
        @response[:publisher] = @collection.publisher
        @response[:objectcount] = count_items_in_collection @collection.pid
      }
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    update_object_permission_check(params[:dri_model_collection][:manager_groups_string],params[:dri_model_collection][:manager_users_string], params[:id])

    @collection = retrieve_object!(params[:id])

    #For sub collections will have to set a governing_collection_id
    #Create a sub collections controller?

    set_access_permissions(:dri_model_collection)

    if !valid_permissions?
      flash[:error] = t('dri.flash.error.not_updated', :item => params[:id])
    else
      @collection.update_attributes(params[:dri_model_collection])
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
    enforce_permissions!("create",DRI::Model::Collection)

    set_access_permissions(:dri_model_collection)

    @collection = DRI::Model::Collection.new(params[:dri_model_collection])

    # depositor is not submitted as part of the form
    @collection.depositor = current_user.to_s

    if !valid_permissions?
      flash[:alert] = t('dri.flash.error.not_created')
      render :action => :new
      return
    end

    respond_to do |format|
      if @collection.save

        # We have to create a default reader group
        @group = UserGroup::Group.new(:name => @collection.id, :description => "Default Reader group for collection #{    @collection.id}")
        @group.save

        format.html { flash[:notice] = t('dri.flash.notice.collection_created')
            redirect_to :controller => "collections", :action => "show", :id => @collection.id }
        format.json {
          @response = {}
          @response[:id] = @collection.pid
          @response[:title] = @collection.title
          @response[:description] = @collection.description
          @response[:publisher] = @collection.publisher
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
        delete_files(object)
        object.delete
      end
      @collection.reload
      @collection.delete
    end

    respond_to do |format|
      format.html { flash[:notice] = t('dri.flash.notice.collection_deleted')
      redirect_to :controller => "collections", :action => "index" }
    end

  end

  private

    def valid_permissions?
      if ((params[:dri_model_collection][:private_metadata].blank? || params[:dri_model_collection][:private_metadata]==UserGroup::Permissions::INHERIT_METADATA) ||
       (params[:dri_model_collection][:master_file].blank? || params[:dri_model_collection][:master_file]==UserGroup::Permissions::INHERIT_MASTERFILE) ||
       (params[:dri_model_collection][:read_groups_string].blank? && params[:dri_model_collection][:read_users_string].blank?) ||
       (params[:dri_model_collection][:manager_users_string].blank? && params[:dri_model_collection][:manager_groups_string].blank? && params[:dri_model_collection][:edit_users_string].blank? && params[:dri_model_collection][:edit_groups_string].blank?))
         return false
      else
         return true
      end
   end

   def delete_files(object)
     local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d",
                                                                { :f => object.id, :d => 'masterContent' } ],
                                            :order => "version DESC")
     local_file_info.each { |file| file.destroy }
     FileUtils.remove_dir(Rails.root.join(Settings.dri.files).join(object.id), :force => true)

     Storage::S3Interface.delete_bucket(object.id.sub('dri:', ''))
   end

   def count_items_in_collection collection_id
      solr_query = "(is_governed_by_ssim:\"info:fedora/" + collection_id +
                   "\" OR is_member_of_collection_ssim:\"info:fedora/" + collection_id + "\")"

      solr_query << " AND status_ssim:published" unless current_user

      ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
    end

    def get_items_in_collection collection_id
      results = Array.new
      solr_query = "(is_governed_by_ssim:\"info:fedora/" + collection_id +
                   "\" OR is_member_of_collection_ssim:\"info:fedora/" + collection_id + "\")"

      solr_query << " AND status_ssim:published" unless current_user

      result_docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "500", :fl => "id,title_tesim")
      result_docs.each do | doc |
        results.push({ :id => doc['id'], :title => doc["title_tesim"][0] })
      end

      return results
    end

    def get_collections
      results = Array.new
      solr_query = "has_model_ssim:\"info:fedora/afmodel:DRI_Model_Collection\""
      unless current_user 
        solr_query << " AND status_ssim:published"
      end
      result_docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :fl => "id,title_tesim,description_tesim,publisher_tesim")
      result_docs.each do | doc |
        results.push({ :id => doc['id'], :title => doc["title_tesim"][0], :description => doc["description_tesim"][0], :publisher => doc["publisher_tesim"][0] })
      end
      return results
    end

end

