class AccessControlsController < ApplicationController

  def edit
    enforce_permissions!('edit', params[:id])
    @object = retrieve_object!(params[:id])

    respond_to do |format|
      format.js
    end
  end

  def update
    @object = retrieve_object!(params[:id])
    @object.collection? ? enforce_permissions!('manage_collection', params[:id]) : enforce_permissions!('edit', params[:id])

    params[:batch][:read_users_string] = params[:batch][:read_users_string].to_s.downcase
    params[:batch][:edit_users_string] = params[:batch][:edit_users_string].to_s.downcase
    params[:batch][:manager_users_string] = params[:batch][:manager_users_string].to_s.downcase if params[:batch][:manager_users_string].present?
    
    if @object.collection?
      if valid_permissions?
        updated = @object.update_attributes(update_params)
      end
    else
      updated = @object.update_attributes(update_params)
    end

    #purge params from update action
    purge_params

    if updated
      flash[:notice] = t('dri.flash.notice.access_controls_updated')
    else
      flash[:alert] = t('dri.flash.error.not_updated', item: params[:id])
    end

    respond_to do |format|
      format.html  { redirect_to controller: 'catalog', action: 'show', id: @object.id }
    end
  end


  private
    
    def purge_params
      params.delete(:batch)
      params.delete(:_method)
      params.delete(:authenticity_token)
      params.delete(:commit)
      params.delete(:action)
    end

    def update_params
      params.require(:batch).permit(:read_groups_string, :read_users_string, :master_file_access, :edit_groups_string, :edit_users_string)
    end

    def valid_permissions?
      if (@object.governing_collection_id.blank? &&
        ((params[:batch][:read_groups_string].blank? && params[:batch][:read_users_string].blank?) ||
        (params[:batch][:manager_users_string].blank? && params[:batch][:edit_users_string].blank?)))
        false
      else
        true
      end
    end
end