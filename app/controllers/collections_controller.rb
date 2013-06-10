# Controller for the Collection model
#
class CollectionsController < AssetsController
  before_filter :authenticate_user!, :only => [:index, :create, :new, :show, :edit, :update]

  # Shows list of user's collections
  #
  def index
    @mycollections = DRI::Model::Collection.find(:depositor => current_user.to_s)

    respond_to do |format|
      format.html
      format.json { 
        collectionhash = []
        @mycollections.each do |collection|
          collectionhash << { :id => collection.id,
                               :title => collection.title,
                               :description => collection.description,
                               :publisher => collection.publisher,
                               :objectcount => collection.governed_items.count + collection.items.count }.to_json
        end
        @mycollections = collectionhash
      }
    end
  end

  # Creates a new model.
  #
  def new
    enforce_permissions!("create", DRI::Model::Collection)
    @collection = DRI::Model::Collection.new

    respond_to do |format|
      format.html
    end
  end

  # Edits an existing model.
  #
  def edit
    enforce_permissions!("edit",params[:id])
    @collection = retrieve_object(params[:id])

    respond_to do |format|
      format.html
    end
  end

  # Retrieves an existing model.
  #
  def show
    enforce_permissions!("show",params[:id])
    @collection = retrieve_object(params[:id])

    respond_to do |format|
      format.html  
      format.json  {
        @response = {}
        @response[:id] = @collection.pid
        @response[:title] = @collection.title
        @response[:description] = @collection.description
        @response[:publisher] = @collection.publisher
        @response[:objectcount] = @collection.governed_items.count + @collection.items.count
      }
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    #TODO:: Update Access Controls page
    ###Update depending on whats change
    if params[:dri_model_collection][:manager_groups_string].present? or params[:dri_model_collection][:manager_users_string].present?
      enforce_permissions!("manage_collection", params[:id])
   else
      enforce_permissions!("edit",params[:id])
    end

    @collection = retrieve_object(params[:id])
    
    #Temp delete embargo [Waiting for hydra bug fix]
    params[:dri_model_collection].delete(:embargo)

    @collection.update_attributes(params[:dri_model_collection])
    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.updated', :item => params[:id])
      format.html  { render :action => "edit" }
    end
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    enforce_permissions!("create",DRI::Model::Collection)
    @collection = DRI::Model::Collection.new(params[:dri_model_collection])
    #Clears permissions for current_user so do first
    @collection.apply_depositor_metadata(current_user.to_s)
    @collection.manager_users_string=current_user.to_s

    respond_to do |format|
      if @collection.save

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

end

