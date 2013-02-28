class RelationshipsController < AssetsController

  def create
    object = ActiveFedora::Base.find(params[:id], {:cast => true})
    collection = Collection.find(params[:collection_id])

    collection.items << object
    collection.save

    redirect_to :controller => "collections", :action => "show", :id => params[:collection_id]  
  end

end
