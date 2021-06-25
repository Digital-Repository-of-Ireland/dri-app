require 'doi/datacite'

class MintDoiJob
  @queue = :doi

  def self.perform(doi_id)
    return unless Settings.doi.enable == true && DoiConfig

    doi = DataciteDoi.find(doi_id)
    return if doi.nil?

    Rails.logger.info "Mint DOI for #{doi.object_id}"
    client = DOI::Datacite.new(doi)
    client.metadata
    client.mint
  end
end
