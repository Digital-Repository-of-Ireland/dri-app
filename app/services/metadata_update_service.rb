# Encapsulates all side effects that follow a successful metadata update:
# persisting and indexing, DOI sync, preservation, and linked data.
#
# Usage:
#   MetadataUpdateService.new(object, current_user).call
#
class MetadataUpdateService
  def initialize(object, user)
    @object = object
    @user   = user
  end

  def call
    @object.increment_version
    save_and_index!
    preserve
    enqueue_linked_data
  end

  private

  def save_and_index!
    @object.index_needs_update = false
    @doi_sync = DoiSyncService.new(@object, reason: 'metadata updated')

    @saved = false
    ApplicationRecord.transaction do
      begin
        @doi   = @doi_sync.sync_metadata
        @saved = @object.save && @object.update_index
        raise ActiveRecord::Rollback unless @saved
      rescue RSolr::Error::Http
        raise ActiveRecord::Rollback
      end
    end

    unless @saved
      Rails.logger.error "Could not save object #{@object.alternate_id}"
      raise DRI::Exceptions::InternalError
    end

    @doi_sync.enqueue_job(@doi) if @doi
  end

  def preserve
    Preservation::Preservator.new(@object).preserve(['descMetadata'])
  end

  def enqueue_linked_data
    return unless AuthoritiesConfig
    return unless @object.geographical_coverage.present? || @object.coverage.present?

    DRI.queue.push(LinkedDataJob.new(@object.alternate_id))
  rescue StandardError => e
    Rails.logger.error "Unable to submit linked data job: #{e.message}"
  end
end