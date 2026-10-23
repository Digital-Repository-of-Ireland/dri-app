# frozen_string_literal: true
module DRIBatchIngest::BatchSummaries
  extend ActiveSupport::Concern

  def user_batches
    batches = {}

    @ingests.each do |i|
      next unless i.batches.first
      batch = i.batches.first

      batches[batch.id] = {
        total: batch.media_objects.count,
        pending: batch.media_objects.excluding_failed.pending.count,
        completed: batch.media_objects.status('COMPLETED').count,
        failed: batch.media_objects.status('FAILED').count
      }
    end

    batches
  end
end