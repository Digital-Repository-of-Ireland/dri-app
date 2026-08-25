# frozen_string_literal: true

module Preservation
  # Reads Moab signature catalogs - either the object's current one on
  # disk, or a specific prior version's, given its manifest path - and
  # looks up a file's catalog path by its content signature.
  class SignatureCatalogLookup
    include Preservation::PreservationHelpers

    def initialize(object, version)
      @object = object
      @version = version
    end

    def existing_filepath(file_path)
      file_signature = ::Moab::FileSignature.from_file(Pathname.new(file_path))

      current.catalog_filepath(file_signature)
    rescue Moab::FileNotFoundException
      nil
    end

    # The object's current (on-disk) signature catalog.
    def current
      storage_object = ::Moab::StorageObject.new(object.alternate_id, aip_dir(object.alternate_id))
      storage_version = storage_object.current_version

      unless ::Moab::SignatureCatalog.xml_pathname_exist?(manifest_path(object.alternate_id, storage_version.version_id))
        raise DRI::Exceptions::MoabError, "Invalid MOAB version"
      end

      storage_version.signature_catalog
    end

    # A signature catalog read from a specific (typically prior-version)
    # manifest path.
    def from_path(manifest_path)
      catalog = Moab::SignatureCatalog.new(digital_object_id: object.alternate_id)
      catalog.parse(Pathname.new(File.join(manifest_path, 'signatureCatalog.xml')).read)
      catalog
    end

    private

    attr_reader :object, :version
  end
end
