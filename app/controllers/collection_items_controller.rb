class CollectionItemsController < AssetsController

  def update

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
          flash[:alert] = t('dri.flash.alert.not_added_to_collection') 
          redirect_to :controller => "objects", :action => "edit", :id => params[:object_id]
        }
        format.json { render :json => @collection.errors}
      end
    end

  end

  def destroy

    @object = ActiveFedora::Base.find(params[:id], {:cast => true})
    @collection = Collection.find(params[:collection_id])

    @collection.items.delete(@object)
    
    if @object.save
      respond_to do |format|
        format.html { flash[:notice] = t('dri.flash.notice.removed_from_collection')
        }
        format.json { render :json => @collection }
      end
    else
      respond_to do |format|
        format.html {
          flash[:alert] = t('dri.flash.alert.not_removed_from_collection')
        }
        format.json { render :json => @object.errors}
      end
    end
  
    redirect_to :controller => "collections", :action => "show", :id => params[:collection_id]
  end

  def set_current_collection
    session[:current_collection] = params[:id]

    respond_to do |format|
        format.html {
          flash[:notice] = t('dri.flash.notice.current_collection_set', :collection => params[:id])
          redirect_to :controller => "collections", :action => "index"
        }
    end
  end

  def clear_current_collection
    session.delete(:current_collection)    

    respond_to do |format|
        format.html {
          flash[:notice] = t('dri.flash.notice.current_collection_cleared')
          redirect_to :controller => "collections", :action => "index"
        }
    end
  end

end
