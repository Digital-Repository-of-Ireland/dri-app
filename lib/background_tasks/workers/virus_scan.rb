class VirusScan
  @queue = "virus_scan_queue"

  def self.perform(object_id)
    puts "Scanning #{object_id} for viruses"
  end
end
