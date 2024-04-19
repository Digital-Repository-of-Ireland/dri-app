class CollectionConfig < ActiveRecord::Base
  
  def self.can_export?(collection_id)
    return false unless CollectionConfig.exists?(collection_id: collection_id)
    config = find_by(collection_id: collection_id)
    config.allow_export || false
  end
end