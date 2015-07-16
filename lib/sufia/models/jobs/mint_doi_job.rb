require 'doi/datacite'

class MintDoiJob < ActiveFedoraIdBasedJob

  def queue_name
    :mint_doi
  end

  def run
    Rails.logger.info "Mint DOI for #{id}"
    
    if object.descMetadata.has_versions?
      doi = DataciteDoi.create(object_id: id, mod_version: object.descMetadata.versions.last.uri)
    else
      doi = DataciteDoi.create(object_id: id)
    end

    client = DOI::Datacite.new(doi)
    client.metadata
    client.mint
    object.doi = doi.doi

    object.save
  end

end
