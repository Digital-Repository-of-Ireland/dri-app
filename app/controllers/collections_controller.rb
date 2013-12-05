# Controller for the Collection model
#
require 'storage/s3_interface'

class CollectionsController < CatalogController

  include UserGroup::SolrAccessControls

  before_filter :authenticate_user!, :only => [:create, :new, :edit, :update]

  # Shows list of user's collections
  #
  def index
    @collections = filtered_collections(params[:view])
    @collection_counts = {}

    @collections.each do |collection|
      @collection_counts[collection[:id]] = count_collection_items collection[:id]
    end

    respond_to do |format|
      format.html
      format.json {
        collectionhash = []
        @collections.each do |collection|
          collectionhash << { :id => collection[:id],
                               :title => collection[:title],
                               :description => collection[:description],
                               :objectcount => collection_counts[collection[:id]] }.to_json
        end
        @collections = collectionhash
      }
    end

  end

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
    @object.publisher = [""]
    @object.rights = [""]
    @object.type = [ "Collection" ]

    respond_to do |format|
      format.html
    end
  end

  # Edits an existing model.
  #
  def edit
    enforce_permissions!("edit",params[:id])
    @collections = filtered_collections
    @object = retrieve_object!(params[:id])

    respond_to do |format|
      format.html
    end
  end

  # Retrieves an existing model.
  #
  def show
    enforce_permissions!("show",params[:id])

    @collection = retrieve_object!(params[:id])
    @children = collection_items params[:id]

    respond_to do |format|
      format.html
      format.json  {
        @response = {}
        @response[:id] = @collection.pid
        @response[:title] = @collection.title
        @response[:description] = @collection.description
        @response[:objectcount] = count_items_in_collection @collection.pid
      }
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    update_object_permission_check(params[:batch][:manager_groups_string],params[:batch][:manager_users_string], params[:id])

    @object = retrieve_object!(params[:id])

    #For sub collections will have to set a governing_collection_id
    #Create a sub collections controller?

    set_access_permissions(:batch)

    if !valid_permissions?
      flash[:error] = t('dri.flash.error.not_updated', :item => params[:id])
    else
      @object.update_attributes(params[:batch])
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

    set_access_permissions(:batch)

    @collection = Batch.new
    if @collection.type == nil
      @collection.type = ["Collection"]
    end

    if !@collection.type.include?("Collection")
      @collection.type.push("Collection")
    end
    @collection.update_attributes(params[:batch])


    # depositor is not submitted as part of the form
    @collection.depositor = current_user.to_s

    if !valid_permissions?
      flash[:alert] = t('dri.flash.error.not_created')
      @object = @collection
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
      if (
       #(params[:batch][:master_file].blank? || params[:batch][:master_file]==UserGroup::Permissions::INHERIT_MASTERFILE) ||
       (params[:batch][:read_groups_string].blank? && params[:batch][:read_users_string].blank?) ||
       (params[:batch][:manager_users_string].blank? && params[:batch][:manager_groups_string].blank? && params[:batch][:edit_users_string].blank? && params[:batch][:edit_groups_string].blank?))
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

      Storage::S3Interface.delete_bucket(object.id.sub('dri:', ''))
    end

    def count_collection_items collection_id
      solr_query = "(is_governed_by_ssim:\"info:fedora/" + collection_id +
                   "\" OR is_member_of_collection_ssim:\"info:fedora/" + collection_id + "\")"

      unless (current_user && current_user.is_admin?)
        fq = published_or_permitted_filter
      end

      ActiveFedora::SolrService.count(solr_query, :defType => "edismax", :fq => fq)
    end

    def collection_items collection_id
      results = Array.new

      solr_query = "(is_governed_by_ssim:\"info:fedora/" + collection_id +
                   "\" OR is_member_of_collection_ssim:\"info:fedora/" + collection_id + "\") "

      unless (current_user && current_user.is_admin?)
        fq = published_or_permitted_filter
      end

      result_docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "500", :fl => "id,title_tesim", :fq => fq)
      result_docs.each do | doc |
        results.push({ :id => doc['id'], :title => doc["title_tesim"][0] })
      end

      return results
    end

    def filtered_collections(view = 'mine')
      results = Array.new
      solr_query = "+object_type_sim:Collection"

      case view
        when 'all'  
          fq = published_or_permitted_filter unless (current_user && current_user.is_admin?)
        when 'mine'
          fq = manager_and_edit_filter unless (current_user && current_user.is_admin?)
        when 'published'
          fq = published_filter
        else
          fq = published_or_permitted_filter unless (current_user && current_user.is_admin?)
      end 
      
      result_docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :fl => "id,title_tesim,description_tesim", :fq => fq)
      result_docs.each do | doc |
        results.push({ :id => doc['id'], :title => doc["title_tesim"][0], :description => doc["description_tesim"][0] })
      end

      return results
    end
end

