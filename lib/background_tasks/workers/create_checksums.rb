require 'digest'

class CreateChecksums
  @queue = "create_checksums_queue"

  def self.perform(object_id)
    puts "Creating checksums of #{object_id} asset"

    datastream = "masterContent"
    @object = ActiveFedora::Base.find(object_id,{:cast => true})
    @local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d",
                                                             { :f => @object.id, :d => datastream } ],
                                      :order => "version DESC",
                                      :limit => 1)
    filename = @local_file_info.first.path

    # If the checksum is already set should we be comparing them?
    # What happens when the asset is updated then?
    @object.md5 = md5(filename) 
    @object.sha1 = sha256(filename) 

    @object.save

  end
end
