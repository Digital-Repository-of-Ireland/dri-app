require 'checksum'

class CreateChecksumsJob < ActiveFedoraPidBasedJob

  def queue_name
    :create_checksums
  end

  def run
    Rails.logger.info "Creating checksums of #{generic_file_id} asset"

    @local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE 'content'",
                                                             { :f => generic_file_id } ],
                                      :order => "version DESC",
                                      :limit => 1)
    filename = @local_file_info.first.path

    # If the checksum is already set should we be comparing them?
    # What happens when the asset is updated then?
    object.checksum_md5 = Checksum.md5(filename) 
    object.checksum_sha256 = Checksum.sha256(filename) 
    object.checksum_rmd160 = Checksum.rmd160(filename)
    object.save
  end

end