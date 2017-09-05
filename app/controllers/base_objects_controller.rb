class BaseObjectsController < CatalogController
  include DRI::Doi

  def actor
    @actor ||= DRI::Object::Actor.new(@object, current_user)
  end

  def doi
    @doi ||= DataciteDoi.where(object_id: @object.noid)
    @doi.empty? ? nil : @doi.current
  end

  protected

    def create_params
      params.require(:digital_object).permit!
    end

    def update_params
      params.require(:digital_object).except!(
        :read_groups_string,
        :read_users_string,
        :master_file_access,
        :edit_groups_string,
        :edit_users_string
      ).permit!
    end

    def purge_params
      params.delete(:digital_object)
      params.delete(:_method)
      params.delete(:authenticity_token)
      params.delete(:commit)
      params.delete(:action)
    end

    # Updates the licence.
    #
    def set_licence
      @object = retrieve_object!(params[:id])

      licence = params[:digital_object][:licence]
      if licence.present?
        @object.licence = licence
        version = @object.object_version || '1'
        @object.object_version = (version.to_i + 1).to_s
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
        format.html { redirect_to controller: 'catalog', action: 'show', id: @object.noid }
      end
    end
end
