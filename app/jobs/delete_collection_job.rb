class DeleteCollectionJob < ActiveFedoraIdBasedJob

  def queue_name
    :delete_collection
  end

  def run
    Rails.logger.info "Deleting all objects in #{object.noid}"
    object.destroy
  end
end
