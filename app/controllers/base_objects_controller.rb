class BaseObjectsController < CatalogController
  include DRI::Citable
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

    def save_and_index
      @object.index_needs_update = false

      DRI::DigitalObject.transaction do
        if doi
          doi.update_metadata(update_params.select { |key, _value| doi.metadata_fields.include?(key) })
          new_doi_if_required(@object, doi, 'metadata updated')
        end

        begin
          raise ActiveRecord::Rollback unless @object.save && @object.update_index

          return true
        rescue RSolr::Error::Http => e
          raise ActiveRecord::Rollback
        end
      end

      false
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
          flash[:notice] = t('dri.flash.notice.licence_updated')
        else
          flash[:error] = t('dri.flash.error.licence_not_updated')
        end
        format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
      end
    end
end
