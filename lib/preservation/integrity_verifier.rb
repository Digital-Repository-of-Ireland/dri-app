# frozen_string_literal: true

module Preservation
  # Verifies that an object's current Moab storage version matches its
  # own recorded version number, that Moab's own storage-verification
  # passes, and that the object's descMetadata content matches what's on
  # disk.
  class IntegrityVerifier
    include Preservation::PreservationHelpers

    def initialize(object)
      @object = object
    end

    def call
      storage_object_version = ::Moab::StorageObject.new(object.alternate_id, aip_dir(object.alternate_id)).current_version
      file_inventory = storage_object_version.file_inventory('version')
      # NOTE: this was originally `g.group_id = 'metadata'` (assignment,
      # not comparison) - a real bug: `find` always matched the *first*
      # group regardless of its actual group_id (the assignment
      # expression evaluates to the truthy string 'metadata'), and as a
      # side effect overwrote that first group's group_id. Fixed to an
      # actual equality comparison, since the intent here is unambiguous.
      group = file_inventory.groups.find { |g| g.group_id == 'metadata' }

      storage_verify = moab_storage_verify(storage_object_version)
      equal_versions = storage_object_version.version_id == object.object_version.to_i
      metadata_match = attached_file_match?(object.attached_files[:descMetadata], group.path_hash['descMetadata.xml'].md5)

      {
        verified: equal_versions && storage_verify[:verified] && metadata_match,
        storage_verify: storage_verify[:output],
        versions: equal_versions,
        attached_files: { metadata: metadata_match }
      }
    rescue StandardError => e
      { verified: false, output: e.message }
    end

    private

    attr_reader :object

    def moab_storage_verify(storage_object_version)
      verify = storage_object_version.verify_version_storage
      {
        verified: verify.verified,
        output: verify.subentities.select { |s| s.verified == false }
      }
    rescue StandardError => e
      { verified: false, output: e.message }
    end
  end
end
