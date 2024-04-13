class DeleteCollectionJob < IdBasedJob

  def queue_name
    :delete_collection
  end

  def run
    Rails.logger.info "Deleting all objects in #{object.alternate_id}"
    object.destroy

    CollectionConfig.find_by(collection_id: object.alternate_id).destroy if CollectionConfig.exists?(collection_id: object.alternate_id)
  end
end
