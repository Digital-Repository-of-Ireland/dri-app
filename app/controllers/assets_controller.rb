class AssetsController < ApplicationController
  include Hydra::AccessControlsEnforcement
  include DRI::Metadata
  include DRI::Model

  def retrieve_object(id)
    return objs = ActiveFedora::Base.find(id,{:cast => true})
  end
  
end
