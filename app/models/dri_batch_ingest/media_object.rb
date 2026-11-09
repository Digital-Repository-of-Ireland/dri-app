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

    def metadata_part
      parts.detect(&:metadata?)
    end

    def status_label
      if finished_processing?
        succeeded? ? 'COMPLETED' : 'FAILED'
      else
        failed? ? 'FAILED' : 'PENDING'
      end
    end

    def display_name
      metadata_part&.file_name || "Object #{id}"
    end

    def error_message
      parts.filter_map(&:error_message).first
    end

    def repository_location
      location = metadata_part&.file_location
      location if location.present? && !location.start_with?('error:')
    end
  end
end
