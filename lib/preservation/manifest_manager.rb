# frozen_string_literal: true

module Preservation
  # Builds and writes the Moab version-inventory and signature-catalog
  # manifests for an object: either creating them fresh (first version)
  # or updating them by applying a set of added/modified/deleted file
  # changes to the previous version's inventory.
  class ManifestManager
    include Preservation::PreservationHelpers

    def initialize(object, version)
      @object = object
      @version = version
      @catalog_lookup = SignatureCatalogLookup.new(object, version)
    end

    def create_or_update(datastream_list)
      if object.object_version == 1
        create(version_id: object.object_version)
      else
        # metadata files cannot be added or deleted after object creation
        update(modified: { 'metadata' => datastream_list })
      end
    end

    def create(version_id: 1)
      signature_catalog = Moab::SignatureCatalog.new(digital_object_id: object.alternate_id, version_id: version_id)
      new_version_id = signature_catalog.version_id
      new_manifest_path = Pathname.new(manifest_path(object.alternate_id, new_version_id))

      version_inventory = content_file_inventory(new_version_id)
      version_additions = signature_catalog.version_additions(version_inventory)
      signature_catalog.update(version_inventory, Pathname.new(data_path(object.alternate_id, new_version_id)))

      file_inventory_difference = Moab::FileInventoryDifference.new
      file_inventory_difference.compare(Moab::FileInventory.new, version_inventory)

      write_manifests_to_xml([signature_catalog, version_inventory, version_additions, file_inventory_difference], new_manifest_path)
      manifest_file_inventory(new_version_id).write_xml_file(new_manifest_path)

      true
    rescue StandardError => e
      Rails.logger.error "unable to create manifests: #{e}"
      false
    end

    # changes: hash with keys :added, :modified and :deleted. Each is an
    # array of filenames
    def update(changes)
      previous_version_id, previous_manifest_path = find_previous_manifest_path(version)
      return create(version_id: version) if previous_manifest_path == nil
      
      @version_inventory = file_inventory_from_path(previous_version_id, previous_manifest_path)
      @version_inventory.version_id = version
      perform_changes(changes)

      signature_catalog = catalog_lookup.from_path(previous_manifest_path)
      version_additions = signature_catalog.version_additions(@version_inventory)
      signature_catalog.update(@version_inventory, Pathname.new(data_path(object.alternate_id, version)))
      file_inventory_difference = compare_with_previous_file_inventory(previous_version_id, previous_manifest_path)

      write_manifests_to_xml([signature_catalog, @version_inventory, version_additions, file_inventory_difference])
      write_manifests_to_xml([manifest_file_inventory(version)])

      true
    rescue StandardError => e
      Rails.logger.error "unable to update manifests: #{e}"
      false
    end

    def file_inventory_from_path(version_id, manifest_path)
      version_inventory = Moab::FileInventory.new(type: 'version', version_id: version_id, digital_object_id: object.alternate_id)
      version_inventory.parse(Pathname.new(File.join(manifest_path, 'versionInventory.xml')).read)

      version_inventory
    end

    private

    attr_reader :object, :version, :catalog_lookup

    def content_file_inventory(version_id)
      version_inventory = Moab::FileInventory.new(type: 'version', version_id: version_id, digital_object_id: object.alternate_id)
      file_group = Moab::FileGroup.new(group_id: 'metadata').group_from_directory(Pathname.new(metadata_path(object.alternate_id, version_id)))
      version_inventory.groups << file_group
      file_group = Moab::FileGroup.new(group_id: 'content').group_from_directory(Pathname.new(content_path(object.alternate_id, version_id)))
      version_inventory.groups << file_group

      version_inventory
    end

    def manifest_file_inventory(version_id)
      manifest_inventory = Moab::FileInventory.new(type: 'manifests', digital_object_id: object.alternate_id, version_id: version_id)
      manifest_inventory.groups << Moab::FileGroup.new(group_id: 'manifests').group_from_directory(manifest_path(object.alternate_id, version_id), false)
      manifest_inventory
    end

    def find_previous_manifest_path(current_version_id)
      previous_version_id = current_version_id - 1

      previous_version_id.downto(1) do |vid|
        path = manifest_path(object.alternate_id, vid)
        return [vid, path] if File.exist?(path)
      end

      [nil, nil]
    end

    def write_manifests_to_xml(manifests, path = nil)
      path ||= Pathname.new(manifest_path(object.alternate_id, version))
      manifests.each { |manifest| manifest.send(:write_xml_file, path) }
    end

    def compare_with_previous_file_inventory(previous_version_id, previous_manifest_path)
      last_version_inventory = file_inventory_from_path(previous_version_id, previous_manifest_path)
      file_inventory_difference = Moab::FileInventoryDifference.new
      file_inventory_difference.compare(last_version_inventory, @version_inventory)
    end

    def perform_changes(changes)
      delete_file_instances(changes[:deleted]) if changes.key?(:deleted)
      add_file_instances(changes[:added]) if changes.key?(:added)
      modify_file_instances(changes[:modified]) if changes.key?(:modified)
    end

    def add_file_instances(changes)
      changes.each_key do |type|
        path = path_for_type(type, object.alternate_id, version)
        changes[type].each { |file| moab_add_file_instance(path, file, type) }
      end
    end

    def delete_file_instances(changes)
      changes.each_key do |type|
        changes[type].each do |file|
          @file_group = @version_inventory.group(type.to_s)
          remove_file_instance(file)
        end
      end
    end

    def modify_file_instances(changes)
      changes.each_key do |type|
        changes[type].each do |file|
          @version_inventory.groups.find { |g| g.group_id == type.to_s }.remove_file_having_path(File.basename(file))
          moab_add_file_instance(path_for_type(type, object.alternate_id, version), file, type)
        end
      end
    end

    def moab_add_file_instance(path, file, type)
      file_signature = Moab::FileSignature.new
      file_signature.signature_from_file(Pathname.new(file))

      file_instance = Moab::FileInstance.new
      file_instance.instance_from_file(Pathname.new(file), Pathname.new(path))

      @version_inventory.groups.find { |g| g.group_id == type.to_s }.add_file_instance(file_signature, file_instance)
    end

    def remove_file_instance(file)
      signature = @file_group.path_hash[file]
      file_manifestation = @file_group.signature_hash[signature]
      return unless file_manifestation

      instances = file_manifestation.instances
      if instances.size > 1
        file_manifestation.instances = instances.reject { |fi| fi.path == file }
      else
        @file_group.remove_file_having_path(file)
      end
    end
  end
end
