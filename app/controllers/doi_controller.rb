class DoiController < ApplicationController
  include DRI::Doi

  def show
    @object_id = params[:object_id]

    if DoiConfig.nil?
      flash[:alert] = t('dri.flash.alert.doi_not_configured')
      @history = {}
    else
      @available = ActiveFedora::Base.exists?(@object_id)

      doi = "#{DoiConfig.prefix}/DRI.#{params[:id]}"

      @history = DataciteDoi.where(object_id: @object_id).ordered
      current = @history.first

      flash[:notice] = t('dri.flash.notice.doi_not_latest') unless doi == current.doi
    end
  end

  def update
    enforce_permissions!('edit', params[:object_id])

    @object = retrieve_object!(params[:object_id])

    mint_doi(@object, params[:modified]) if @object.status == 'published'
    flash[:notice] = t('dri.flash.notice.collection_doi_request')

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'show', id: @object.id }
      format.json do
        response = { id: @object.id }
        render json: response, status: :accepted
      end
    end
  end
end
