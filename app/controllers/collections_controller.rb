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
    @collection = DRI::Model::Collection.new

    respond_to do |format|
      format.html
    end
  end

  # Edits an existing model.
  #
  def edit
    @collection = retrieve_object(params[:id])

    respond_to do |format|
      format.html
    end
  end

  # Retrieves an existing model.
  #
  def show
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
    @collection = retrieve_object(params[:id])
    
    @collection.update_attributes(params[:dri_model_collection])
    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.updated', :item => params[:id])
      format.html  { render :action => "edit" }
    end
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    @collection = DRI::Model::Collection.new(params[:dri_model_collection])
    @collection.apply_depositor_metadata(current_user.to_s)

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

