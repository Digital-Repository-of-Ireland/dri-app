class Embed3dController < ApplicationController
  layout "embedded"

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!
  before_action :authenticate_admin!

  def show
    @document = SolrDocument.find(params[:object_id])

    # assets ordered by label, excludes preservation only files
    @assets = @document.assets(ordered: true)

    file = @assets.find(ifnone = nil) { |asset| asset.key? 'id' and asset.id == params[:id] }


    raise DRI::Exceptions::NotFound unless file['file_type_tesim'].include? '3d'
    raise DRI::Exceptions::NotFound if file.preservation_only?

    @generic_file = file
     
    @presenter = DRI::ObjectInCatalogPresenter.new(@document, view_context)
  
    respond_to do |format|
      format.html
    end    
  end

end