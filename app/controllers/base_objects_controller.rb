require 'metadata_helpers'
require 'institute_helpers'

class BaseObjectsController < CatalogController

  before_filter :authenticate_user_from_token!
  before_filter :authenticate_user!

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
      params.require(:batch).permit!
    end

    def purge_params
      params.delete(:batch)
      params.delete(:_method)
      params.delete(:authenticity_token)
      params.delete(:commit)
      params.delete(:action)
    end

    def doi_update_required?
      doi = DataciteDoi.where(object_id: params[:id]).current
      update_doi = if doi.is_a?(DataciteDoi)
        doi.update?(params[:batch])
      else
        false
      end
    end

end
