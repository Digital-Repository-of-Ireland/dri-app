# Persists a DRI::DigitalObject, updates its Solr index, and syncs any
# associated DOI record — all inside a single transaction.
#
# Distinct from MetadataUpdateService in that:
#   - DOI fields come from the caller-supplied update_params, not from the
#     object's current attributes (needed by ObjectsController#update).
#   - Raises DRI::SolrBadRequest on Solr 400 responses so the controller can
#     surface a meaningful flash alert.
#
# Usage:
#   result = ObjectSaveService.new(object, doi: doi, doi_params: doi_params).call
#   result.success?   # => true / false
#   result.error      # => exception or nil
#   result.doi_sync   # => DoiSyncService instance (call #enqueue_job on it after the transaction)
#
class ObjectSaveService
  Result = Struct.new(:success, :error, :doi_sync, keyword_init: true) do
    def success? = success
    def failure? = !success
  end

  def initialize(object, doi: nil, doi_params: {}, reason: 'metadata updated')
    @object     = object
    @doi        = doi
    @doi_params = doi_params
    @reason     = reason
    @doi_sync   = nil
    @saved      = false
  end

  def call
    @object.index_needs_update = false

    ApplicationRecord.transaction do
      sync_doi_in_transaction if @doi
      save_and_index!
    end

    if @saved
      Result.new(success: true, error: nil, doi_sync: @doi_sync)
    else
      Result.new(success: false, error: nil, doi_sync: nil)
    end
  rescue DRI::SolrBadRequest => e
    Result.new(success: false, error: e, doi_sync: nil)
  end

  private

  def sync_doi_in_transaction
    @doi_sync = DoiSyncService.new(@object, reason: @reason)
    @doi.update_metadata(map_doi_params)
    @doi_sync.create_new_doi_if_required(@doi)
  end

  def map_doi_params
    mapped = @doi_params.dup
    mapped['resource_type'] = mapped.delete('type') if mapped.key?('type')
    mapped
  end

  def save_and_index!
    @saved = @object.save && @object.update_index
    raise ActiveRecord::Rollback unless @saved
  rescue RSolr::Error::Http => e
    raise DRI::SolrBadRequest.new(e.request, e.response) if e.response[:status] == 400
    raise ActiveRecord::Rollback
  end
end