class CollectionConfig < ActiveRecord::Base

  def self.can_export_full_collection?(collection_id)
    return false unless CollectionConfig.exists?(collection_id: collection_id)
    config = find_by(collection_id: collection_id)
    config.allow_full_collection_export || false
  end

  
  def self.can_export?(collection_id)
    return false unless CollectionConfig.exists?(collection_id: collection_id)
    config = find_by(collection_id: collection_id)
    config.allow_export || false
  end
end
