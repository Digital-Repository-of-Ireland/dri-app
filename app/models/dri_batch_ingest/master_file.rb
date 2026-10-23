# frozen_string_literal: true
module DRIBatchIngest
  class MasterFile < ActiveRecord::Base
    belongs_to :media_object, class_name: 'DRIBatchIngest::MediaObject'

    END_STATES = %w[CANCELLED COMPLETED FAILED].freeze

    scope :metadata, -> { find_by(metadata: true) }

    def metadata?
      metadata == true
    end

    def preservation?
      preservation == true
    end

    def process(file = nil)
      raise "MasterFile is already being processed" if status_code.present? && !finished_processing?
    end

    def status?(value)
      status_code == value
    end

    def failed?
      status?('FAILED')
    end

    def succeeded?
      status?('COMPLETED')
    end

    def finished_processing?
      END_STATES.include?(status_code)
    end
  end
end
