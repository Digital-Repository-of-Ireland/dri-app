class DoiController < ApplicationController

  def show
    enforce_permissions!("show_digital_object", params[:object_id])

    @object_id = params[:object_id]

    if DoiConfig.nil?
      flash[:alert] = t('dri.flash.alert.doi_not_configured') 
      @history = {}
    else
      doi = "#{DoiConfig.prefix}/DRI.#{params[:id]}"
     
      @history = DataciteDoi.where(object_id: @object_id).ordered  
      current = @history.first
    
      flash[:notice] = t('dri.flash.notice.doi_not_latest') unless (doi == current.doi)       
    end

  end

end
