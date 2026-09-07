# frozen_string_literal: true

module Preservation
  # Writes an object's attributes.json snapshot and individual datastream
  # XML files into its Moab metadata directory for a given version.
  class AttributesWriter
    include Preservation::PreservationHelpers

    def initialize(object, version)
      @object = object
      @version = version
    end

    def attributes_path
      File.join(metadata_path(object.alternate_id, version), 'attributes.json')
    end

    def write_attributes
      attributes = object.attributes.merge(
        "access_control" =>
          object.access_control.attributes.except(
            'id', 'digital_object_type', 'digital_object_id'
          )
      )

      attributes['alternate_identifier'] = object.alternate_id
      if object.governing_collection
        attributes['governing_collection_alternate_identifier'] = object.governing_collection.alternate_id
      end

      File.write(attributes_path, attributes.to_json)
      true
    rescue StandardError => e
      Rails.logger.error "unable to write attributes: #{e}"
      false
    end

    # Writes a single datastream's XML content into the metadata
    # directory as "<name>.xml". Returns nil (not false) when the
    # datastream itself has no XML content - matching the original's
    # early `return if data.nil?`, which callers treat as "nothing to do"
    # rather than a failure.
    def write_datastream(name, datastream)
      data = datastream.to_xml
      return if data.nil?

      File.write(datastream_path(name), data)
      true
    rescue StandardError => e
      Rails.logger.error "unable to write datastream: #{e}"
      false
    end

    def datastream_path(name)
      File.join(metadata_path(object.alternate_id, version), "#{name}.xml")
    end

    private

    attr_reader :object, :version
  end
end
