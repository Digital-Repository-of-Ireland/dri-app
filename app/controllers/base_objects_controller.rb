class BaseObjectsController < CatalogController
  include DRI::Citable
  include DRI::Versionable

  def doi
    @doi ||= DataciteDoi.where(object_id: @object.noid)
    @doi.empty? ? nil : @doi.current
  end

  protected

    def create_params
      params.require(:digital_object).permit!
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

    # Updates the licence.
    #
    def set_licence
      @object = retrieve_object!(params[:id])

      licence = params[:digital_object][:licence]
      if licence.present?
        @object.licence = licence
        @object.increment_version
      end

      updated = @object.save

      if updated
        record_version_committer(@object, current_user)

        # Do the preservation actions
        preservation = Preservation::Preservator.new(@object)
        preservation.preserve
      end

      respond_to do |format|
        if updated
          flash[:notice] = t('dri.flash.notice.updated', item: params[:id])
        else
          flash[:error] = t('dri.flash.error.licence_not_updated')
        end
        format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.noid }
      end
    end
end
