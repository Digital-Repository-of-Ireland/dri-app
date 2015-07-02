require 'doi/datacite'

class MintDoiJob < ActiveFedoraPidBasedJob

  def queue_name
    :mint_doi
  end

  def run
    Rails.logger.info "Mint DOI for #{pid}"

    doi = DataciteDoi.where(object_id: pid).current

    client = DOI::Datacite.new(doi)
    client.metadata
    client.mint
    object.doi = doi.doi

    object.save
  end

end
