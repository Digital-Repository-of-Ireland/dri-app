require 'utils'

class DeleteCollectionJob < ActiveFedoraIdBasedJob

  def queue_name
    :delete_collection
  end

  def run
    Rails.logger.info "Deleting all objects in #{object.id}"
    object.delete
  end
end
