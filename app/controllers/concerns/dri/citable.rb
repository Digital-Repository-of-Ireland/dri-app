module DRI::Citable
  extend ActiveSupport::Concern

  def new_doi_if_required(object, doi, modified)
    return if Settings.doi.enable != true || DoiConfig.nil?

    return unless (doi.changed? && doi.mandatory_update?) && object.status == "published"

    new_doi(object, modified)
  end

  def mint_or_update_doi(object, doi = nil)
    return if Settings.doi.enable != true || DoiConfig.nil?

    if @new_doi && @new_doi.persisted?
      Resque.enqueue(MintDoiJob, @new_doi.id)
    elsif doi && doi.changed?
      doi.clear_changed
      Resque.enqueue(UpdateDoiJob, doi.id)
    end
  end

  def new_doi(object, modified)
    return if Settings.doi.enable != true || DoiConfig.nil?
    @new_doi = DataciteDoi.create(
      object_id: object.alternate_id,
      modified: modified,
      mod_version: object.object_version
    )
    object.doi = @new_doi.doi
  end
end
