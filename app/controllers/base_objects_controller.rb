require 'metadata_helpers'
require 'institute_helpers'

class BaseObjectsController < CatalogController
  include DRI::Doi

  def actor
    @actor ||= DRI::Object::Actor.new(@object, current_user)
  end

  def doi
    @doi ||= DataciteDoi.where(object_id: @object.id)
    @doi.empty? ? nil : @doi.current
  end

  protected

  def create_params
    params.require(:batch).permit!
  end

  def update_params
    params.require(:batch).except!(:read_groups_string, :read_users_string, :master_file_access, :edit_groups_string, :edit_users_string).permit!
  end

  def purge_params
    params.delete(:batch)
    params.delete(:_method)
    params.delete(:authenticity_token)
    params.delete(:commit)
    params.delete(:action)
  end

  # Updates the licence.
  #
  def set_licence
    @object = retrieve_object!(params[:id])

    licence = params[:batch][:licence]

    if licence.present?
      @object.licence = licence
    end

    respond_to do |format|
      if @object.save
        flash[:notice] = t('dri.flash.notice.updated', item: params[:id])
      else
        flash[:error] = t('dri.flash.error.licence_not_updated')
      end
      format.html { redirect_to controller: 'catalog', action: 'show', id: @object.id }
    end
  end
  
end
