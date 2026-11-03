# frozen_string_literal: true
module DRIBatchIngest
  class IngestBatch < ActiveRecord::Base
    belongs_to :user_ingest, class_name: 'DRIBatchIngest::UserIngest'
    has_many :media_objects, class_name: 'DRIBatchIngest::MediaObject'

    serialize :report, type: Hash, coder: JSON

    def confirmed? = confirmed_at.present?

    def discard!
      transaction do
        media_objects.each(&:destroy)
        ingest = user_ingest
        destroy!
        ingest.destroy! if ingest.batches.reload.empty?
      end
    end

    def finished?
      media_objects.all?(&:finished_processing?)
    end

    def finished_at
      media_objects.empty? ? '-' : media_objects.order(:created_at).last.finished_at
    end

    def summary
      parts = DRIBatchIngest::MasterFile.where(media_object_id: media_objects.select(:id))
      assets = parts.where(metadata: [nil, false], preservation: [nil, false])
      {
        objects: media_objects.count,
        assets: assets.count,
        preservation_files: parts.where(preservation: true).count,
        total_bytes: parts.pluck(:file_size).sum(&:to_i),
        objects_without_assets: media_objects.where.not(id: assets.select(:media_object_id)).count,
        missing_files: parts.where(file_size: nil).count
      }
    end
  end
end
