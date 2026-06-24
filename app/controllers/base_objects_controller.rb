class BaseObjectsController < CatalogController
  include DRI::Versionable

  def doi
    @doi ||= DataciteDoi.where(object_id: @object.alternate_id)
    @doi.empty? ? nil : @doi.current
  end

  protected

    def create_params
      params.fetch(:digital_object, {}).permit!
    end

    def update_params
      params.require(:digital_object).except(
        :read_groups_string,
        :read_users_string,
        :master_file_access,
        :edit_groups_string,
        :edit_users_string
      ).permit!
    end

    def set_licence
      @object  = retrieve_object!(params[:id])
      licence  = params[:digital_object][:licence]

      if licence.present?
        @object.licence = licence
        @object.increment_version
      end

      updated = @object.save

      if updated
        ObjectPostSaveService.new(@object).call { record_version_committer(@object, current_user, 'update') }
        flash[:notice] = t('dri.flash.notice.licence_updated')
      else
        flash[:error] = t('dri.flash.error.licence_not_updated')
      end

      respond_to { |format| format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id } }
    end

    def set_copyright
      @object    = retrieve_object!(params[:id])
      copyright  = params[:digital_object][:copyright]

      if copyright.present?
        @object.copyright = copyright
        @object.increment_version
      end

      updated = @object.save

      if updated
        ObjectPostSaveService.new(@object).call { record_version_committer(@object, current_user, 'update') }
        flash[:notice] = t('dri.flash.notice.copyright_updated')
      else
        flash[:error] = t('dri.flash.error.copyright_not_updated')
      end

      respond_to { |format| format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id } }
    end

    def visibility_label(field)
      case field
      when 'registered' then 'logged-in'
      when 'public'     then 'public'
      else                   'restricted'
      end
    end
end