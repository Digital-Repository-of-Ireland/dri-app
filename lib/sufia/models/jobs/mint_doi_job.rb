require 'doi/datacite'

class MintDoiJob < ActiveFedoraIdBasedJob

  def queue_name
    :mint_doi
  end

  def run
    Rails.logger.info "Mint DOI for #{id}"
    
    doi = DataciteDoi.where(object_id: id).current

    client = DOI::Datacite.new(doi)
    client.metadata
    client.mint
    object.doi = doi.doi

    object.save
  end

end
