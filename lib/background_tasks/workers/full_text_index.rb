class FullTextIndex
  @queue = "full_text_index_queue"

  def self.perform(object_id)
    Rails.logger.info "Creating full text index of #{object_id} asset"
  end
end
