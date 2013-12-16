require 'doi/datacite'

class MintDoiJob < ActiveFedoraPidBasedJob

  def queue_name
    :mint_doi
  end

  def run
    Rails.logger.info "Mint DOI for #{pid}"

    doi = DOI::Datacite.new(object)
    doi.metadata
    doi.mint
    object.doi = doi.doi

    object.save
  end

end
