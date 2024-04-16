class CollectionConfigsController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!
  before_action :authorize_cm!

  def show
  	@document = SolrDocument.find(params[:collection_id])
  	@config = CollectionConfig.find_or_create_by(collection_id: params[:collection_id])
  end

  def update
    config = CollectionConfig.find_by(collection_id: params[:collection_id])
    config.update!(collection_config_params)
    flash[:notice] = t('dri.collection.config.saved')
    respond_to do |format|
      format.html { redirect_to my_collections_url(config.collection_id) }
    end 
  end

  private

  def collection_config_params
    params.require(:collection_config).permit(:allow_export)
  end
end