require 'active_support/core_ext/string'
module Hydra
  module Datastream
    # Implements Hydra RightsMetadata XML terminology for asserting access permissions
    class RightsMetadata < ActiveFedora::OmDatastream       
      include UserGroup::RightsMetadataDatastreamOverride

      def prefix
        '' # add a prefix for solr index terms if you need to namespace identical terms in multiple data streams 
      end
    end
  end
end
