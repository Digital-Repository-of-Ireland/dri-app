class CreateSurrogates
  @queue = "asset_queue"

  def self.perform(object_id)
    puts "Creating surrogates for #{object_id}"
  end
end
