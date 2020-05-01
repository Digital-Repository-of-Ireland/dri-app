module DRI::Citable
  extend ActiveSupport::Concern

  def update_doi(object, doi, modified)
    return if Settings.doi.enable != true || DoiConfig.nil?

    if doi.changed? && object.status == "published"
      doi.mandatory_update? ? mint_doi(object, modified) : doi_metadata_update(object)
      doi.clear_changed
    end
  end

  def mint_doi(object, modified)
    return if Settings.doi.enable != true || DoiConfig.nil?

    DataciteDoi.create(object_id: object.noid, modified: modified, mod_version: object.object_version)
    DRI.queue.push(MintDoiJob.new(object.noid))
  end

  def doi_metadata_update(object)
    DRI.queue.push(UpdateDoiJob.new(object.noid))
  end
end
