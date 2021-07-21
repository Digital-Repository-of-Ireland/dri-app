require 'doi/datacite'

class UpdateDoiJob
  @queue = :doi

  def self.perform(doi_id)
    doi = DataciteDoi.find(doi_id)
    return if doi.nil?

    client = DOI::Datacite.new(doi)
    client.metadata
  end
end
