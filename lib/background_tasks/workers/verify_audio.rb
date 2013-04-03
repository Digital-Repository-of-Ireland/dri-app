class VerifyAudio
  @queue = "verify_audio_queue"

  def self.perform(object_id)
    puts "Verifying that the file for #{object_id} is a valid audio file"
  end
end
