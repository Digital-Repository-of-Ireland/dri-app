class CreateChecksums
  @queue = "create_checksums_queue"

  def self.perform(object_id)
    puts "Creating checksums of #{object_id} asset"
  end
end
