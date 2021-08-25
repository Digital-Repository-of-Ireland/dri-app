require 'doi/datacite'

class MintDoiJob
  @queue = :doi

  def self.perform(doi_id)
    return unless Settings.doi.enable == true && DoiConfig

    doi = DataciteDoi.find(doi_id)
    return if doi.nil?

    Rails.logger.info "Mint DOI for #{doi.object_id}"
    client = DOI::Datacite.new(doi)

    if client.doi_exists? && doi.status.nil?
      doi.status = 'minted'
      doi.save
      return
    end

    case client.metadata
    when 201
      doi.status = client.mint == 201 ? 'minted' : 'error'
    when 422
      doi.status = 'unprocessable'
    else
      doi.status = 'failed'
    end

    doi.save
  end
end
