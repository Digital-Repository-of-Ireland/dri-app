# frozen_string_literal: true

module DRI
  module Formatters
    class OpenAire < OAI::Provider::Metadata::Format
      # Maps a record onto its OpenAIRE oaire:resourceType attributes
      # (resourceTypeGeneral + COAR resource-type URI) and label.
      #
      # Each entry's `match` checks the record's own type predicate first
      # (e.g. record.text?), falling back to the record's declared
      # object_type string - exactly mirroring the original if/elsif
      # chain, including matching order (which matters here: 3d and
      # interactiveresource are distinct branches that happen to produce
      # an identical result, preserved as separate entries for fidelity).
      class ResourceTypeMapper
        TYPES = [
          {
            match: ->(record, type) { record.text? || type == "text" },
            resource_type_general: "literature",
            uri: "http://purl.org/coar/resource_type/c_18cf",
            label: "text"
          },
          {
            match: ->(record, type) { record.image? || type == "image" },
            resource_type_general: "dataset",
            uri: "http://purl.org/coar/resource_type/c_c513",
            label: "image"
          },
          {
            match: ->(record, type) { record.video? || type == "video" },
            resource_type_general: "dataset",
            uri: "http://purl.org/coar/resource_type/c_12ce",
            label: "video"
          },
          {
            match: ->(record, type) { record.audio? || type == "sound" },
            resource_type_general: "dataset",
            uri: "http://purl.org/coar/resource_type/c_18cc",
            label: "sound"
          },
          {
            match: ->(record, type) { record.threeD? || type == "3d" },
            resource_type_general: "dataset",
            uri: "http://purl.org/coar/resource_type/c_e9a0",
            label: "interactive resource"
          },
          {
            match: ->(record, type) { record.interactive_resource? || type == "interactiveresource" },
            resource_type_general: "dataset",
            uri: "http://purl.org/coar/resource_type/c_e9a0",
            label: "interactive resource"
          },
          {
            match: ->(_record, type) { type == "software" },
            resource_type_general: "software",
            uri: "http://purl.org/coar/resource_type/c_5ce6",
            label: "software"
          },
          {
            match: ->(_record, type) { type == "dataset" },
            resource_type_general: "dataset",
            uri: "http://purl.org/coar/resource_type/c_1843",
            label: "other"
          }
        ].freeze

        DEFAULT = {
          resource_type_general: "other research product",
          uri: "http://purl.org/coar/resource_type/c_1843",
          label: "other"
        }.freeze

        def self.for(record)
          type = record.object_type.first.downcase

          entry = TYPES.find { |candidate| candidate[:match].call(record, type) } || DEFAULT
          entry.except(:match)
        end
      end
    end
  end
end