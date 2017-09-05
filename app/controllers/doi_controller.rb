class DoiController < ApplicationController
  include DRI::Doi

  def show
    @object_id = params[:object_id]

    if DoiConfig.nil?
      flash[:alert] = t('dri.flash.alert.doi_not_configured')
      @history = {}
    else
      @available = DRI::DigitalObject.exists?(noid: @object_id)
      @reason = t('dri.views.catalog.legends.doi_deleted', id: @object_id) unless @available

      if(@available)
        doc = SolrDocument.new(ActiveFedora::SolrService.query("id:#{@object_id}").first)
        if !doc.published?
          @reason = t('dri.views.catalog.legends.doi_not_available')
          @available = false
        end
      end

      id, version = params[:id].split('-')
      version = 0 if version.nil?
      raise DRI::Exceptions::NotFound unless DataciteDoi.exists?(object_id: id, version: version)

      doi = "#{DoiConfig.prefix}/DRI.#{params[:id]}"

      @history = DataciteDoi.where(object_id: @object_id).ordered
      current = @history.first

      if @available && doi == current.doi
        redirect_to(catalog_path(@object_id))
        return
      end

      flash[:notice] = t('dri.flash.notice.doi_not_latest') if @available
    end
  end

  def update
    enforce_permissions!('edit', params[:object_id])

    @object = retrieve_object!(params[:object_id])

    mint_doi(@object, params[:modified]) if @object.status == 'published'
    flash[:notice] = t('dri.flash.notice.collection_doi_request')

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'show', id: @object.noid }
      format.json do
        response = { id: @object.noid }
        render json: response, status: :accepted
      end
    end
  end
end
