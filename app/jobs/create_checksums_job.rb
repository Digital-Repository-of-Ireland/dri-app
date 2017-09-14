require 'checksum'

class CreateChecksumsJob < ActiveFedoraIdBasedJob

  def queue_name
    :create_checksums
  end

  def run
    Rails.logger.info "Creating checksums of #{generic_file_id} asset"

    filename = object.path

    # If the checksum is already set should we be comparing them?
    # What happens when the asset is updated then?
    object.checksum_md5 = Checksum.md5(filename)
    object.checksum_sha256 = Checksum.sha256(filename)
    object.checksum_rmd160 = Checksum.rmd160(filename)
    object.save
  end

end
