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
    return objs = ActiveFedora::Base.find(id,{:cast => true})
  end
  
end
