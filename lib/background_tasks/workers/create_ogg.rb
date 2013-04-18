class CreateOgg
  @queue = "create_ogg_queue"

  def self.perform(object_id)
    puts "Creating Ogg version of #{object_id} asset, if required"
  end
end
