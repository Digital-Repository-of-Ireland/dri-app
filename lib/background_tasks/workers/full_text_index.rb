class FullTextIndex
  @queue = "full_text_index_queue"

  def self.perform(object_id)
    puts "Creating full text index of #{object_id} asset"
  end
end
