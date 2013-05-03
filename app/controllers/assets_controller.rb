# Base controller for the asset managing controllers.
#
class AssetsController < ApplicationController
  include Hydra::AccessControlsEnforcement
  include DRI::Metadata
  include DRI::Model
  #Moved from application controller due to routing issues with devise
  include Blacklight::Catalog

  # Retrieves a Fedora Digital Object by ID
  def retrieve_object(id)
    enforce_edit_permissions!
    return objs = ActiveFedora::Base.find(id,{:cast => true})
  end

  private
  def enforce_edit_permissions!
    unless can? :edit, params[:id]
        raise Hydra::AccessDenied.new(t('dri.flash.alert.edit_permission'), :edit, params[:id])
    end
  end
  
end