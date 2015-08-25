require 'doi/datacite'

class UpdateDoiJob < ActiveFedoraIdBasedJob

  def queue_name
    :doi
  end

  def run
    Rails.logger.info "Update DOI metadata for #{id}"
    
    doi = DataciteDoi.where(object_id: id).current

    client = DOI::Datacite.new(doi)
    client.metadata
  end

end
