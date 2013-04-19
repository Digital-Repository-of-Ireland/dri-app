class VerifyAudio
  @queue = "verify_audio_queue"

  def self.perform(object_id)
    puts "Verifying that the file for #{object_id} is a valid audio file"

    datastream = "masterContent"
    @object = ActiveFedora::Base.find(object_id,{:cast => true})
    @local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d",
                                                             { :f => @object.id, :d => datastream } ],
                                      :order => "version DESC",
                                      :limit => 1)
    filename = @local_file_info.first.path

    unless Validators.valid_file_type?(filename, @object.whitelist_type, @object.whitelist_subtypes)
      puts "Found a problem"
    end

  end
end
