class CollectionConfig < ActiveRecord::Base
  
  def self.can_export?(collection_id)
    config = find_by(collection_id: collection_id)
    return true unless config

    config.allow_export
  end
end