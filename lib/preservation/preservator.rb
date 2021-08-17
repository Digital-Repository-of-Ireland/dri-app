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
      target_path = manifest_path(self.object.alternate_id, self.version)
      if File.directory?(target_path)
        err_string  = "The Moab directory #{target_path} for "\
          "#{self.object.alternate_id} version #{self.version} already exists"
        Rails.logger.error(err_string)
        raise DRI::Exceptions::InternalError, err_string
      end

      make_dir(
        [
          version_path(self.object.alternate_id, self.version),
          metadata_path(self.object.alternate_id, self.version),
          content_path(self.object.alternate_id, self.version)
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
      storage_object = ::Moab::StorageObject.new(object.alternate_id, aip_dir(object.alternate_id))
      storage_version = storage_object.current_version

      if ::Moab::SignatureCatalog.xml_pathname_exist?(manifest_path(object.alternate_id, storage_version.version_id))
        storage_version.signature_catalog
      else
        raise DRI::Exceptions::MoabError, "Invalid MOAB version"
      end
    end

    # moabify_datastream
    # Takes two parameters
    # - name (datastream and file name)
    # - datastream (the value for that key from the datastreams hash
    def moabify_datastream(name, datastream)
      data = datastream.to_xml
      return if data.nil?

      begin
        File.write(File.join(metadata_path(self.object.alternate_id, self.version), "#{name.to_s}.xml"), data)
      rescue StandardError => e
        Rails.logger.error "unable to write datastream: #{e}"
        false
      end
    end

    # preserve
    def preserve(datastreams=nil)
      create_moab_dirs()

      saved = moabify_attributes
      return false unless saved
      dslist = [File.join(metadata_path(object.alternate_id, version), 'attributes.json')]

      if datastreams.present?
        datastreams.each do |ds|
          saved = moabify_datastream(ds, object.attached_files[ds])
          return false unless saved
        end
        dslist.push(datastreams.map { |item| File.join(metadata_path(object.alternate_id, version), item << ".xml") }).flatten!
      end

      if object.object_version == 1
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
      moabify_attributes
      changes[:modified] ||= {}
      changes[:modified]['metadata'] = [File.join(metadata_path(self.object.alternate_id, self.version), 'attributes.json')]

      update_manifests(changes)
    end

    # create_manifests
    def create_manifests
      signature_catalog = Moab::SignatureCatalog.new(digital_object_id: object.alternate_id, version_id: 0)
      new_version_id = signature_catalog.version_id + 1
      new_manifest_path = manifest_path(object.alternate_id, new_version_id)

      version_inventory = Moab::FileInventory.new(type: 'version', version_id: new_version_id, digital_object_id: object.alternate_id)
      file_group = Moab::FileGroup.new(group_id: 'metadata').group_from_directory(Pathname.new(metadata_path(object.alternate_id, new_version_id)))
      version_inventory.groups << file_group
      file_group = Moab::FileGroup.new(group_id: 'content').group_from_directory(Pathname.new(content_path(object.alternate_id, new_version_id)))
      version_inventory.groups << file_group

      version_additions = signature_catalog.version_additions(version_inventory)

      signature_catalog.update(version_inventory, Pathname.new(data_path(object.alternate_id, new_version_id)))

      file_inventory_difference = Moab::FileInventoryDifference.new
      file_inventory_difference.compare(Moab::FileInventory.new(), version_inventory)

      signature_catalog.write_xml_file(Pathname.new(new_manifest_path))
      version_inventory.write_xml_file(Pathname.new(new_manifest_path))
      version_additions.write_xml_file(Pathname.new(new_manifest_path))
      file_inventory_difference.write_xml_file(Pathname.new(new_manifest_path))

      manifest_inventory = Moab::FileInventory.new(type: 'manifests', digital_object_id: object.alternate_id, version_id: new_version_id)
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
      current_manifest_path = manifest_path(object.alternate_id, current_version_id)

      previous_version_id, previous_manifest_path = find_previous_manifest_path(current_version_id)

      last_version_inventory = Moab::FileInventory.new(type: 'version', version_id: previous_version_id, digital_object_id: @object.alternate_id)
      last_version_inventory.parse(Pathname.new(File.join(previous_manifest_path, 'versionInventory.xml')).read)

      @version_inventory = Moab::FileInventory.new(type: 'version', version_id: previous_version_id, digital_object_id: @object.alternate_id)
      @version_inventory.parse(Pathname.new(File.join(previous_manifest_path, 'versionInventory.xml')).read)
      @version_inventory.version_id = current_version_id

      if changes.key?(:deleted)
        changes[:deleted].keys.each do |type|
          changes[:deleted][type].each do |file|
            @file_group = @version_inventory.group(type.to_s)
            remove_file_instance(file)
          end
        end
      end

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

      signature_catalog = Moab::SignatureCatalog.new(digital_object_id: object.alternate_id)
      signature_catalog.parse(Pathname.new(File.join(previous_manifest_path, 'signatureCatalog.xml')).read)
      version_additions = signature_catalog.version_additions(@version_inventory)
      signature_catalog.update(@version_inventory, Pathname.new(data_path(object.alternate_id, self.version)))
      file_inventory_difference = Moab::FileInventoryDifference.new
      file_inventory_difference.compare(last_version_inventory, @version_inventory)

      signature_catalog.write_xml_file(Pathname.new(current_manifest_path))
      @version_inventory.write_xml_file(Pathname.new(current_manifest_path))
      version_additions.write_xml_file(Pathname.new(current_manifest_path))
      file_inventory_difference.write_xml_file(Pathname.new(current_manifest_path))

      manifest_inventory = Moab::FileInventory.new(type: 'manifests', digital_object_id: object.alternate_id, version_id: current_version_id)
      manifest_inventory.groups << Moab::FileGroup.new(group_id: 'manifests').group_from_directory(current_manifest_path, recursive=false)
      manifest_inventory.write_xml_file(Pathname.new(current_manifest_path))

      true
    rescue StandardError => e
      Rails.logger.error "unable to update manifests: #{e}"
      false
    end

    def verify
      storage_object = ::Moab::StorageObject.new(object.alternate_id, aip_dir(object.alternate_id))
      storage_object_version = storage_object.current_version

      begin
        file_inventory = storage_object_version.file_inventory('version')
        group = file_inventory.groups.select { |g| g.group_id = 'metadata' }.first

        storage_verify = moab_storage_verify(storage_object_version)
      rescue Exception => e
         return { verified: false, output: e.message }
      end

      equal_versions = storage_object_version.version_id == object.object_version.to_i
      metadata_match = attached_file_match?(object.attached_files[:descMetadata], group.path_hash['descMetadata.xml'].md5)

      {
        verified: equal_versions && storage_verify[:verified] && metadata_match,
        storage_verify: storage_verify[:output],
        versions: equal_versions,
        attached_files: { metadata: metadata_match }
      }
    end

    private

      def find_previous_manifest_path(current_version_id)
        previous_version_id = current_version_id - 1

        previous_version_id.downto(1) do |vid|
          path = manifest_path(object.alternate_id, vid)
          return [vid, path] if File.exist?(path)
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

      def moabify_attributes
        attributes = object.attributes.merge("access_control" =>
                       object.access_control.attributes.except(
                         'id','digital_object_type','digital_object_id'
                       )
                     )

        attributes['alternate_indentifier'] = object.alternate_id
        if object.governing_collection
          attributes['governing_collection_alternate_identifier'] = object.governing_collection.alternate_id
        end

        File.write(File.join(metadata_path(self.object.alternate_id, self.version), 'attributes.json'), attributes.to_json)
        true
      rescue StandardError => e
        Rails.logger.error "unable to write attributes: #{e}"
        false
      end

      def path_for_type(type)
        if type == 'content'
          content_path(object.alternate_id, self.version)
        elsif type == 'metadata'
          metadata_path(object.alternate_id, self.version)
        end
      end

      def remove_file_instance(file)
        signature = @file_group.path_hash[file]
        file_manifestation = @file_group.signature_hash[signature]
        instances = file_manifestation.instances
        if instances.size > 1
          file_manifestation.instances = instances.reject { |fi| fi.path == file }
        else
          @file_group.remove_file_having_path(file)
        end
      end

      def attached_file_match?(file, moab_md5)
          (Checksum.md5_string(file.content) == moab_md5) ||
        (Checksum.md5_string(file.to_xml) == moab_md5)
      end
  end
end
