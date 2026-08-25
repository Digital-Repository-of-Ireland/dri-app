# frozen_string_literal: true

module DRI
  module Formatters
    class OpenAire < OAI::Provider::Metadata::Format
      # Resolves the uri/label pair for oaire:licenseCondition. When the
      # record's licence has no url of its own, falls back to the
      # record's catalog page as the uri (matching the original's
      # behaviour exactly).
      class LicenseConditionBuilder
        def self.for(record)
          licence = record.licence
          return nil unless licence

          uri = licence.url.present? ? licence.url : "https://repository.dri.ie/catalog/#{record.id}"
          { uri: uri, label: licence.name }
        end
      end
    end
  end
end
