module DRIBatchIngest
  module BatchSummaries
    extend ActiveSupport::Concern

    def batch_counts(batch)
      {
        total: batch.media_objects.count,
        pending: batch.media_objects.excluding_failed.pending.count,
        completed: batch.media_objects.status('COMPLETED').count,
        failed: batch.media_objects.status('FAILED').count
      }
    end

    def user_batches
      @ingests.each_with_object({}) do |ingest, batches|
        batch = ingest.batches.first
        next unless batch&.confirmed?

        batches[batch.id] = batch_counts(batch)
      end
    end
  end
end