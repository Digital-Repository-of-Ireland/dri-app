# Controller for the Collection model
#
class CollectionsController < AssetsController
  before_filter :authenticate_user!, :only => [:index, :create, :new, :edit, :update]

  # Shows list of user's collections
  #
  def index
    @mycollections = DRI::Model::Collection.all

    respond_to do |format|
      format.html
      format.json { 
        collectionhash = []
        @mycollections.each do |collection|
          collectionhash << { :id => collection.id,
                               :title => collection.title,
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
    @document_fedora = DRI::Model::Collection.new

    respond_to do |format|
      format.html
    end
  end

  # Edits an existing model.
  #
  def edit
    @document_fedora = retrieve_object(params[:id])

    respond_to do |format|
      format.html
    end
  end

  # Retrieves an existing model.
  #
  def show
    @document_fedora = retrieve_object(params[:id])

    respond_to do |format|
      format.html  
      format.json  {
        @response = {}
        @response[:id] = @document_fedora.pid
        @response[:title] = @document_fedora.title
        @response[:description] = @document_fedora.description
        @response[:publisher] = @document_fedora.publisher
        @response[:objectcount] = @document_fedora.governed_items.count + @document_fedora.items.count
      }
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    @document_fedora = retrieve_object(params[:id])
    
    @document_fedora.update_attributes(params[:dri_model_collection])
    respond_to do |format|
      flash["notice"] = t('dri.flash.notice.updated', :item => params[:id])
      format.html  { render :action => "edit" }
    end
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    @document_fedora = DRI::Model::Collection.new(params[:dri_model_collection])
    #@document_fedora.creator = current_user.to_s
    respond_to do |format|
      if @document_fedora.save
        format.html { flash[:notice] = t('dri.flash.notice.collection_created')
            redirect_to :controller => "collections", :action => "show", :id => @document_fedora.id }
        format.json {
          @response = {}
          @response[:id] = @document_fedora.pid
          @response[:title] = @document_fedora.title
          @response[:description] = @document_fedora.description
          @response[:publisher] = @document_fedora.publisher
          render(:json => @response, :status => :created)
        }
      else
        format.html {
          flash["alert"] = @document_fedora.errors.messages.values.to_s
          render :action => :new
        }
        format.json { @document_fedora.errors.messages.values.to_s }
      end
    end
  end

end

