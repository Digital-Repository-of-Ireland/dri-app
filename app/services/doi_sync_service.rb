# Syncs a DRI object's metadata to its DataciteDoi record, then either mints
# a new DOI or enqueues an update job, mirroring the logic in DRI::Citable
# but without any dependency on controller concerns.
#
# Usage (full sync — fetches DOI, updates metadata, mints/updates):
#   DoiSyncService.new(object, reason: 'metadata updated').call
#
# Usage (split across a transaction boundary):
#   doi_sync = DoiSyncService.new(object, reason: 'metadata updated')
#   # Inside the transaction:
#   doi = doi_sync.sync_metadata   # fetch, update metadata, conditionally mint; returns doi or nil
#   # After the transaction commits:
#   doi_sync.enqueue_job(doi) if doi
#
class DoiSyncService
  def initialize(object, reason: 'metadata updated')
    @object  = object
    @reason  = reason
    @new_doi = nil
  end

  # Full sync: fetch, update metadata, conditionally mint, enqueue.
  def call
    return unless doi_enabled?

    doi = sync_metadata
    enqueue_job(doi) if doi
  end

  # Fetches the DOI record, updates its metadata from the object's current
  # attributes, and conditionally mints a new DOI — all suitable for running
  # inside a transaction. Sets @new_doi as a side effect so that enqueue_job
  # can branch correctly afterward. Returns the doi, or nil if not found.
  def sync_metadata
    return unless doi_enabled?

    doi = DataciteDoi.find_by(object_id: @object.alternate_id)
    return unless doi

    doi.update_metadata(derived_metadata_fields(doi))
    create_new_doi_if_required(doi)
    doi
  end

  # Called inside a transaction when the DOI record and its metadata are
  # already managed by the caller (e.g. ObjectSaveService), which passes
  # doi_params directly to doi.update_metadata itself.
  # Sets @new_doi as a side effect so that enqueue_job can branch correctly.
  def create_new_doi_if_required(doi)
    create_new_doi if requires_new_doi?(doi)
  end

  # Enqueues MintDoiJob for a freshly created DOI, or UpdateDoiJob for a
  # changed existing one. Safe to call after the transaction has committed.
  def enqueue_job(doi)
    if @new_doi&.persisted?
      Resque.enqueue(MintDoiJob, @new_doi.id)
    elsif doi.changed?
      doi.clear_changed
      Resque.enqueue(UpdateDoiJob, doi.id)
    end
  end

  private

  def doi_enabled?
    Settings.doi.enable == true && DoiConfig.present?
  end

  def requires_new_doi?(doi)
    doi.changed? && doi.mandatory_update? && @object.status == 'published'
  end

  def create_new_doi
    @new_doi = DataciteDoi.create(
      object_id:   @object.alternate_id,
      modified:    @reason,
      mod_version: @object.object_version
    )
    @object.doi = @new_doi.doi
  end

  # Derives DOI metadata fields from the object's current attributes.
  # Used by sync_metadata. When fields come from update_params instead,
  # the caller (ObjectSaveService) passes them directly to doi.update_metadata.
  def derived_metadata_fields(doi)
    doi.metadata_fields.each_with_object({}) do |field, hash|
      if field == 'type'
        hash['resource_type'] = @object.send(:type)
      elsif @object.respond_to?(field.to_sym)
        hash[field] = @object.send(field.to_sym)
      end
    end
  end
end