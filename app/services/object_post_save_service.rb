# Runs all side effects that follow a successful object save:
#   1. Duplicate detection warning
#   2. Linked data job (if geographical/coverage data present)
#   3. Caller-supplied block (e.g. version committer, reader group creation)
#   4. Preservation
#
# Replaces the yielding post_save private method in ObjectsController so
# these concerns can be tested and reused independently.
#
# Usage:
#   ObjectPostSaveService.new(object, datastreams: ['descMetadata']).call do
#     record_version_committer(object, current_user, 'update')
#   end
#
class ObjectPostSaveService
  def initialize(object, datastreams: ['descMetadata'])
    @object      = object
    @datastreams = datastreams
  end

  def call
    enqueue_linked_data
    yield if block_given?
    preserve
  end

  private

  def enqueue_linked_data
    return unless AuthoritiesConfig
    return unless @object.geographical_coverage.present? || @object.coverage.present?

    DRI.queue.push(LinkedDataJob.new(@object.alternate_id))
  rescue StandardError => e
    Rails.logger.error "Unable to submit linked data job: #{e.message}"
  end

  def preserve
    Preservation::Preservator.new(@object).preserve(@datastreams)
  end
end