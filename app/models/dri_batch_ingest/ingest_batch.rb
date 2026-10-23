# frozen_string_literal: true
module DRIBatchIngest
  class IngestBatch < ActiveRecord::Base
    belongs_to :user_ingest, class_name: 'DRIBatchIngest::UserIngest'
    has_many :media_objects, class_name: 'DRIBatchIngest::MediaObject'

    def finished?
      media_objects.all?(&:finished_processing?)
    end

    def finished_at
      media_objects.empty? ? '-' : media_objects.order(:created_at).last.finished_at
    end
  end
end
