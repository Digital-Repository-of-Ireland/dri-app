class BaseObjectsController < CatalogController
  include DRI::Citable
  include DRI::Versionable

  def doi
    @doi ||= DataciteDoi.where(object_id: @object.id)
    @doi.empty? ? nil : @doi.current
  end

  protected

    def create_params
      params.require(:batch).permit!
    end

    def update_params
      params.require(:batch).except(
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

      licence = params[:batch][:licence]
      if licence.present?
        @object.licence = licence
        @object.object_version ||= '1'
        @object.increment_version
      end

      updated = @object.save

      if updated
        # Do the preservation actions
        preservation = Preservation::Preservator.new(@object)
        preservation.preserve(false, false, ['properties'])
      end

      respond_to do |format|
        if updated
          flash[:notice] = t('dri.flash.notice.updated', item: params[:id])
        else
          flash[:error] = t('dri.flash.error.licence_not_updated')
        end
        format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.id }
      end
    end
end
