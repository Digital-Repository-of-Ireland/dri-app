class DoiController < ApplicationController
  include DRI::Citable

  def show
    @object_id = params[:object_id]

    if DoiConfig.nil?
      flash[:alert] = t('dri.flash.alert.doi_not_configured')
      @history = {}
    else
      @available = DRI::Identifier.object_exists?(@object_id)
      @reason = t('dri.views.catalog.legends.doi_deleted', id: @object_id) unless @available

      if(@available)
        doc = SolrDocument.find(@object_id)
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
        redirect_to(solr_document_path(@object_id))
        return
      end

      flash[:notice] = t('dri.flash.notice.doi_not_latest') if @available
    end
  end

  def update
    enforce_permissions!('edit', params[:object_id])

    @object = retrieve_object!(params[:object_id])

    if @object.status == 'published'
      new_doi(@object, params[:modified])
      mint_or_update_doi(@object)

      flash[:notice] = t('dri.flash.notice.collection_doi_request')
    end

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'show', id: @object.alternate_id }
      format.json do
        response = { id: @object.alternate_id }
        render json: response, status: :accepted
      end
    end
  end
end
