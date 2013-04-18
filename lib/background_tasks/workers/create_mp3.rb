class CreateMp3
  @queue = "create_mp3_queue"

  def self.perform(object_id)
    puts "Creating mp3 version of #{object_id} asset, if required"
  end
end
