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

    def parsed_download_spec
      @parsed_download_spec ||= JSON.parse(download_spec.to_s)
    rescue JSON::ParserError
      {}
    end

    def file_name
      parsed_download_spec['file_name'].presence
    end

    def display_name
      file_name || "File #{id}"
    end

    def kind
      if metadata? then 'Metadata'
      elsif preservation? then 'Preservation file'
      else 'Asset'
      end
    end

    def size_bytes
      file_size.presence&.to_i
    end

    def error_message
      return unless failed? && file_location.to_s.start_with?('error:')

      file_location.sub(/\Aerror:\s*/, '')
    end

    def repository_location
      file_location if succeeded? && file_location.present?
    end
  end
end
