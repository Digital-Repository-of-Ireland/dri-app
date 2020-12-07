require 'doi/datacite'

class MintDoiJob < IdBasedJob

  def queue_name
    :doi
  end

  def run
    if Settings.doi.enable == true && DoiConfig
      Rails.logger.info "Mint DOI for #{id}"

      doi = DataciteDoi.where(object_id: id).current

      client = DOI::Datacite.new(doi)
      client.metadata
      client.mint
      object.doi = doi.doi

      object.increment_version
      object.save

      # Do the preservation actions
      preservation = Preservation::Preservator.new(object)
      preservation.preserve(['properties'])
    end
  end

end
