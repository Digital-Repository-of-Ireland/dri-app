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

    params[:digital_object][:read_users_string] = params[:digital_object][:read_users_string].to_s.downcase
    params[:digital_object][:edit_users_string] = params[:digital_object][:edit_users_string].to_s.downcase
    params[:digital_object][:manager_users_string] = params[:digital_object][:manager_users_string].to_s.downcase if params[:digital_object][:manager_users_string].present?
    params[:digital_object][:object_version] = @object.object_version.next

    permissionchange = permissions_changed?
    updated = @object.update_attributes(update_params) unless @object.collection? && !valid_permissions?

    if updated
      flash[:notice] = t('dri.flash.notice.access_controls_updated')

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(permissionchange, ['properties'])
    else
      flash[:alert] = t('dri.flash.error.not_updated', item: params[:id])
    end

    #purge params from update action
    purge_params

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.noid }
    end
  end

  private

    def purge_params
      params.delete(:digital_object)
      params.delete(:_method)
      params.delete(:authenticity_token)
      params.delete(:commit)
      params.delete(:action)
    end

    def update_params
      params.require(:digital_object).permit(
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
        (params[:digital_object][:manager_users_string].blank? && params[:digital_object][:edit_users_string].blank?)
      )
    end

    def permissions_changed?
      !(@object.read_groups_string == params[:digital_object][:read_groups_string] &&
      @object.edit_users_string == params[:digital_object][:edit_users_string] &&
      @object.manager_users_string == params[:digital_object][:manager_users_string])
    end

end
