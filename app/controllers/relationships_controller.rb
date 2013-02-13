class RelationshipsController < AssetsController

  def create

    @object = ActiveFedora::Base.find(params[:id], {:cast => true})
    @collection = Collection.find(params[:collection_id])

    @collection.items << @object

    if @collection.save
      respond_to do |format|
        format.html { flash[:notice] = t('dri.flash.notice.added_to_collection')
          redirect_to :controller => "collections", :action => "show", :id => params[:collection_id] }
        format.json { render :json => @collection }
      end
    else
      respond_to do |format|
        format.html {
          flash["alert"] = t('dri.flash.notice.not_added_to_collection') 
          redirect_to :controller => "objects", :action => "edit", :id => params[:id]
        }
        format.json { render :json => @collection.errors}
      end
    end

  end

end
