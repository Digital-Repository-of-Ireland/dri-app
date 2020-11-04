require 'moab'

module Preservation
  class Preservator

    include Preservation::PreservationHelpers

    attr_accessor :base_dir, :object, :version

    def initialize(object, version=nil)
     self.object = object
     self.version = version || object.object_version
    end

    # create_moab_dir
    # Creates MOAB preservation directory structure and saves metadata there
    #
    def create_moab_dirs()
      target_path = manifest_path(self.object.id, self.version)
      if File.directory?(target_path)
        err_string  = "The Moab directory #{target_path} for "\
          "#{self.object.id} version #{self.version} already exists"
        Rails.logger.error(err_string)
        raise DRI::Exceptions::InternalError, err_string
      end

      make_dir(
        [
          version_path(self.object.id, self.version),
          metadata_path(self.object.id, self.version),
          content_path(self.object.id, self.version)
        ]
      )
    end

    def existing_filepath(moab_path, filename, file_path)
      file_signature = ::Moab::FileSignature.from_file(Pathname.new(file_path))

      signature_catalog.catalog_filepath(file_signature)
    rescue Moab::FileNotFoundException
      nil
    end

    def signature_catalog
      storage_object = ::Moab::StorageObject.new(object.id, aip_dir(object.id))
      storage_version = storage_object.current_version

      if ::Moab::SignatureCatalog.xml_pathname_exist?(manifest_path(object.id, storage_version.version_id))
        storage_version.signature_catalog
      else
        raise DRI::Exceptions::MoabError, "Invalid MOAB version"
      end
    end

    # moabify_datastream
    # Takes two paramenters
    # - name (datastream and file name)
    # - datastream (the value for that key from the datastreams hash
    def moabify_datastream(name, datastream)
      data = datastream.to_xml
      return if data.nil?

      begin
        File.write(File.join(metadata_path(self.object.id, self.version), "#{name.to_s}.xml"), data)
      rescue StandardError => e
        Rails.logger.error "unable to write datastream: #{e}"
        false
      end
    end

    # moabify_resource
    def moabify_resource
      File.write(File.join(metadata_path(self.object.id, self.version), 'resource.rdf'), object.resource.dump(:ttl))
      true
    rescue StandardError => e
      Rails.logger.error "unable to write resource: #{e}"
      false
    end

    # moabify_permissions
    def moabify_permissions
      File.write(File.join(metadata_path(self.object.id, self.version), 'permissions.rdf'), object.permissions.inspect )
    rescue StandardError => e
      Rails.logger.error "unable to write permissions: #{e}"
      false
    end

    # preserve
    def preserve(resource=false, permissions=false, datastreams=nil)
      create_moab_dirs()
      dslist = []
      added = []
      deleted = []
      modified = []

      if resource
        saved = moabify_resource
        return false unless saved
        dslist << File.join(metadata_path(object.id, version), 'resource.rdf')
      end

      if permissions
        saved = moabify_permissions
        return false unless saved
        dslist << File.join(metadata_path(object.id, version), 'permissions.rdf')
      end

      if datastreams.present?
        #object.reload # we must refresh the datastreams list
        datastreams.each do |ds|
          saved = moabify_datastream(ds, object.attached_files[ds])
          return false unless saved
        end
        dslist.push(datastreams.map { |item| File.join(metadata_path(object.id, version), item << ".xml") }).flatten!
      end

      if @object.object_version == '1'
        created = create_manifests
        return false unless created
      else
        # metadata files cannot be added or deleted after object creation
        updated = update_manifests({ modified: { 'metadata' => dslist } })
        return false unless updated
      end

      true
    end

    # preserve_assets
    def preserve_assets(changes)
      create_moab_dirs()
      moabify_datastream('properties', object.attached_files['properties'])
      changes[:modified] ||= {}
      changes[:modified]['metadata'] = [File.join(metadata_path(self.object.id, self.version), 'properties.xml')]

      update_manifests(changes)
    end

    # create_manifests
    def create_manifests
      signature_catalog = Moab::SignatureCatalog.new(digital_object_id: object.id, version_id: 0)
      new_version_id = signature_catalog.version_id + 1
      new_manifest_path = manifest_path(object.id, new_version_id)

      version_inventory = Moab::FileInventory.new(type: 'version', version_id: new_version_id, digital_object_id: object.id)
      file_group = Moab::FileGroup.new(group_id: 'metadata').group_from_directory(Pathname.new(metadata_path(object.id, new_version_id)))
      version_inventory.groups << file_group
      file_group = Moab::FileGroup.new(group_id: 'content').group_from_directory(Pathname.new(content_path(object.id, new_version_id)))
      version_inventory.groups << file_group

      version_additions = signature_catalog.version_additions(version_inventory)

      signature_catalog.update(version_inventory, Pathname.new(data_path(object.id, new_version_id)))

      file_inventory_difference = Moab::FileInventoryDifference.new
      file_inventory_difference.compare(Moab::FileInventory.new(), version_inventory)

      signature_catalog.write_xml_file(Pathname.new(new_manifest_path))
      version_inventory.write_xml_file(Pathname.new(new_manifest_path))
      version_additions.write_xml_file(Pathname.new(new_manifest_path))
      file_inventory_difference.write_xml_file(Pathname.new(new_manifest_path))

      manifest_inventory = Moab::FileInventory.new(type: 'manifests', digital_object_id: object.id, version_id: new_version_id)
      manifest_inventory.groups << Moab::FileGroup.new(group_id: 'manifests').group_from_directory(new_manifest_path, recursive=false)

      manifest_inventory.write_xml_file(Pathname.new(new_manifest_path))

      true
    rescue StandardError => e
      Rails.logger.error "unable to create manifests: #{e}"
      false
    end

    # update_manifests
    # changes: hash with keys :added, :modified and :deleted. Each is an array of filenames
    def update_manifests(changes)
      current_version_id = version.to_i
      current_manifest_path = manifest_path(object.id, current_version_id)

      previous_version_id, previous_manifest_path = find_previous_manifest_path(current_version_id)

      last_version_inventory = Moab::FileInventory.new(type: 'version', version_id: previous_version_id, digital_object_id: @object.id)
      last_version_inventory.parse(Pathname.new(File.join(previous_manifest_path, 'versionInventory.xml')).read)

      @version_inventory = Moab::FileInventory.new(type: 'version', version_id: previous_version_id, digital_object_id: @object.id)
      @version_inventory.parse(Pathname.new(File.join(previous_manifest_path, 'versionInventory.xml')).read)
      @version_inventory.version_id = current_version_id

      if changes.key?(:added)
        changes[:added].keys.each do |type|
          path = path_for_type(type)

          changes[:added][type].each { |file| moab_add_file_instance(path, file, type) }
        end
      end

      if changes.key?(:modified)
        changes[:modified].keys.each do |type|
          path = path_for_type(type)

          changes[:modified][type].each do |file|
            @version_inventory.groups.find {|g| g.group_id == type.to_s }.remove_file_having_path(File.basename(file))

            moab_add_file_instance(path, file, type)
          end
        end
      end

      if changes.key?(:deleted)
        changes[:deleted].keys.each do |type|
          path = path_for_type(type)

          changes[:deleted][type].each do |file|
            @version_inventory.groups.find {|g| g.group_id == type.to_s }.remove_file_having_path(file)
          end
        end
      end

      signature_catalog = Moab::SignatureCatalog.new(digital_object_id: object.id)
      signature_catalog.parse(Pathname.new(File.join(previous_manifest_path, 'signatureCatalog.xml')).read)
      version_additions = signature_catalog.version_additions(@version_inventory)
      signature_catalog.update(@version_inventory, Pathname.new(data_path(object.id, current_version_id)))
      file_inventory_difference = Moab::FileInventoryDifference.new
      file_inventory_difference.compare(last_version_inventory, @version_inventory)

      signature_catalog.write_xml_file(Pathname.new(current_manifest_path))
      @version_inventory.write_xml_file(Pathname.new(current_manifest_path))
      version_additions.write_xml_file(Pathname.new(current_manifest_path))
      file_inventory_difference.write_xml_file(Pathname.new(current_manifest_path))

      manifest_inventory = Moab::FileInventory.new(type: 'manifests', digital_object_id: object.id, version_id: current_version_id)
      manifest_inventory.groups << Moab::FileGroup.new(group_id: 'manifests').group_from_directory(current_manifest_path, recursive=false)
      manifest_inventory.write_xml_file(Pathname.new(current_manifest_path))

      true
    rescue StandardError => e
      Rails.logger.error "unable to update manifests: #{e}"
      false
    end

    def verify
      storage_object = ::Moab::StorageObject.new(object.id, aip_dir(object.id))
      storage_object_version = storage_object.current_version

      begin
        file_inventory = storage_object_version.file_inventory('version')
        group = file_inventory.groups.select { |g| g.group_id = 'metadata' }.first

        storage_verify = moab_storage_verify(storage_object_version)
      rescue Exception => e
         return { verified: false, output: e.message }
      end

      equal_versions = storage_object_version.version_id == object.object_version.to_i
      metadata_match = metadata_matches?(object, group.path_hash['descMetadata.xml'].md5)
      properties_match = properties_match?(object, group.path_hash['properties.xml'].md5)

      {
        verified: equal_versions && storage_verify[:verified] && metadata_match && properties_match,
        storage_verify: storage_verify[:output],
        versions: equal_versions,
        metadata: metadata_match,
        properties: properties_match
      }
    end

    private

      def find_previous_manifest_path(current_version_id)
        previous_version_id = current_version_id - 1

        [previous_version_id..1].each do |vid|
          path = manifest_path(object.id, previous_version_id)
          if File.exist?(path)
            previous_version_id = vid
            break [vid, path]
          end
        end
      end

      def make_dir(paths)
        FileUtils.mkdir_p(paths)
      rescue StandardError => e
        Rails.logger.error "Unable to create MOAB directory #{paths}. Error: #{e.message}"
        raise DRI::Exceptions::InternalError
      end

      def moab_add_file_instance(path, file, type)
        file_signature = Moab::FileSignature.new()
        file_signature.signature_from_file(Pathname.new(file))

        file_instance = Moab::FileInstance.new()
        file_instance.instance_from_file(Pathname.new(file), Pathname.new(path))

        @version_inventory.groups.find {|g| g.group_id == type.to_s }.add_file_instance(file_signature, file_instance)
      end

      def moab_storage_verify(storage_object_version)
        verify = storage_object_version.verify_version_storage
        {
          verified: verify.verified,
          output: verify.subentities.select { |s| s.verified == false }
        }
      rescue Exception => e
        { verified: false, output: e.message }
      end

      def path_for_type(type)
        if type == 'content'
          content_path(object.id, self.version)
        elsif type == 'metadata'
          metadata_path(object.id, self.version)
        end
      end

      def metadata_matches?(object, moab_metadata_md5)
        (Checksum.md5_string(object.attached_files[:descMetadata].content) == moab_metadata_md5) ||
        (Checksum.md5_string(object.descMetadata.to_xml) == moab_metadata_md5)
      end

      def properties_match?(object, moab_properties_md5)
        (Checksum.md5_string(object.attached_files[:properties].content) == moab_properties_md5) ||
        (Checksum.md5_string(object.properties.to_xml) == moab_properties_md5)
      end
  end
end
