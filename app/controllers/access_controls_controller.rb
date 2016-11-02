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
    params[:batch][:object_version] = @object.object_version.to_i+1

    permissionchange = permissions_changed?

    updated = @object.update_attributes(update_params) unless @object.collection? && !valid_permissions?

    if updated
      flash[:notice] = t('dri.flash.notice.access_controls_updated')

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      if permissionchange
        preservation.preserve(false, true, ['properties'])
      else 
        preservation.preserve(false, false, ['properties'])
      end
    else
      flash[:alert] = t('dri.flash.error.not_updated', item: params[:id])
    end

    #purge params from update action
    purge_params

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'show', id: @object.id }
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
      params.require(:batch).permit(
        :read_groups_string,
        :read_users_string,
        :master_file_access,
        :edit_groups_string,
        :edit_users_string,
        :manager_users_string,
        :object_version
      )
    end

    def valid_permissions?
      if @object.governing_collection_id.blank? &&
        ((params[:batch][:read_groups_string].blank? && params[:batch][:read_users_string].blank?) ||
        (params[:batch][:manager_users_string].blank? && params[:batch][:edit_users_string].blank?))
        false
      else
        true
      end
    end

    def permissions_changed?
      if (@object.read_groups_string.eql?(params[:batch][:read_groups_string]) &&
          @object.edit_users_string.eql?(params[:batch][:edit_users_string]) &&
          @object.manager_users_string.eql?(params[:batch][:manager_users_string]) )
         return false
      end
      return true
    end

end
