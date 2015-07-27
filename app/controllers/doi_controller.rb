class DoiController < ApplicationController

  def show
    enforce_permissions!("show_digital_object", params[:object_id])

    object_id = params[:object_id]
    doi = params[:id]

    @history = DataciteDoi.where(object_id: object_id).ordered  
    current = @history.first
    
    flash[:notice] = t('dri.flash.notice.doi_not_latest') unless (doi == current.doi)   
    
  end

end
