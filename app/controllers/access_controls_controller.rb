class AccessControlsController < ApplicationController
  before_action :read_only, except: :edit
  before_action ->(id=params[:id]) { locked(id) }, except: :edit

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
    
    version = @object.object_version || 1
    params[:batch][:object_version] = version.to_i+1

    permissionchange = permissions_changed?
    updated = @object.update_attributes(update_params) unless @object.collection? && !valid_permissions?

    if updated
      flash[:notice] = t('dri.flash.notice.access_controls_updated')

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(false, permissionchange, ['properties'])
    else
      flash[:alert] = t('dri.flash.error.not_updated', item: params[:id])
    end

    #purge params from update action
    purge_params

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.id }
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
      !(
        @object.governing_collection_id.blank? &&
        (params[:batch][:manager_users_string].blank? && params[:batch][:edit_users_string].blank?)
      )
    end

    def permissions_changed?
      !(@object.read_groups_string == params[:batch][:read_groups_string] &&
      @object.edit_users_string == params[:batch][:edit_users_string] &&
      @object.manager_users_string == params[:batch][:manager_users_string])
    end

end
