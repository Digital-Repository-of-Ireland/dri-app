# frozen_string_literal: true
module DRIBatchIngest
  class MediaObject < ActiveRecord::Base
    belongs_to :ingest_batch, class_name: 'DRIBatchIngest::IngestBatch'
    has_many :parts, class_name: 'DRIBatchIngest::MasterFile'

    scope :status, lambda { |status|
      joins(:parts).where('dri_batch_ingest_master_files.status_code' => status).distinct
    }

    scope :pending, -> { joins(:parts).where('dri_batch_ingest_master_files.status_code' => 'PENDING').distinct }

    scope :excluding_failed, -> { where(['dri_batch_ingest_media_objects.id NOT IN (?)', DRIBatchIngest::MediaObject.status('FAILED').pluck(:id)]) if failed.any? }

    scope :failed, -> { DRIBatchIngest::MediaObject.status('FAILED') }

    scope :completed, -> { DRIBatchIngest::MediaObject.status('COMPLETED') }

    def destroy
      parts.each(&:destroy)
      parts.clear
      super
    end

    def metadata
      parts.all.metadata
    end

    def finished_processing?
      parts.all?(&:finished_processing?)
    end

    def finished_at
      parts.order(:updated_at).last.updated_at
    end

    def succeeded?
      parts.all?(&:succeeded?)
    end

    def failed?
      parts.any?(&:failed?)
    end
  end
end
