require 'checksum'

class CreateChecksumsJob < ActiveFedoraPidBasedJob

  def queue_name
    :create_checksums
  end

  def run
    Rails.logger.info "Creating checksums of #{pid} asset"

    datastream = "content"
    @local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d",
                                                             { :f => pid, :d => datastream } ],
                                      :order => "version DESC",
                                      :limit => 1)
    filename = @local_file_info.first.path

    # If the checksum is already set should we be comparing them?
    # What happens when the asset is updated then?
    object.resource_md5 = Checksum.md5(filename) 
    object.resource_sha256 = Checksum.sha256(filename) 
    object.resource_rmd160 = Checksum.rmd160(filename)
    object.save
  end

end