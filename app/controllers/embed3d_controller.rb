class Embed3dController < ApplicationController
  layout 'embedded'

  def show
    @document = SolrDocument.find(params[:object_id])
    raise DRI::Exceptions::Unauthorized unless can_view?

    # assets ordered by label, excludes preservation only files
    @assets = @document.assets(ordered: true)

    file = @assets.find { |asset| asset.key? 'id' and asset.id == params[:id] }

    raise DRI::Exceptions::NotFound unless file['file_type_tesim'].include? '3d'
    raise DRI::Exceptions::NotFound if file.preservation_only?

    @generic_file = file
    @presenter = DRI::ObjectInCatalogPresenter.new(@document, view_context)

    respond_to do |format|
      format.html
    end
  end

  private
    def can_view?
      (can?(:read, @document.id) && @document.read_master?) || can?(:edit, @document)
    end

end
