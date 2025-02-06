require 'doi/datacite'

class UpdateDoiJob
  @queue = :doi

  def self.perform(doi_id)
    doi = DataciteDoi.find(doi_id)
    return if doi.nil?

    metadata = doi.doi_metadata
    if metadata.resource_type.blank?
      o = DRI::DigitalObject.find_by_alternate_id(doi.object_id)
      metadata.resource_type = o.type
      metadata.save
    end

    client = Doi::Datacite.new(doi)
    client.metadata
  end
end
