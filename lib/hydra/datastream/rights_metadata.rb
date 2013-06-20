require 'active_support/core_ext/string'
module Hydra
  module Datastream
    # Implements Hydra RightsMetadata XML terminology for asserting access permissions
    class RightsMetadata < ActiveFedora::OmDatastream       
      include UserGroup::RightsMetadataDatastreamOverride
    end
  end
end
