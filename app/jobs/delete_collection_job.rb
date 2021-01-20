class DeleteCollectionJob < IdBasedJob

  def queue_name
    :delete_collection
  end

  def run
    Rails.logger.info "Deleting all objects in #{object.alternate_id}"
    object.destroy
  end
end
