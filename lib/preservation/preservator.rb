require 'moab'
require 'preservation/preservation_helpers'

module Preservation
  class Preservator

    include PreservationHelpers

    attr_accessor :base_dir, :object, :version

    def initialize(object)
     self.object = object
     self.version = object.object_version
    end

    # create_moab_dir
    # Creates MOAB preservation directory structure and saves metadata there
    #
    def create_moab_dirs()
        make_dir version_path(self.object.id, self.version) 
        make_dir metadata_path(self.object.id, self.version)
        make_dir content_path(self.object.id, self.version)
    end

    # moabify_datastream
    # Takes two paramenters
    # - name (datastream and file name)
    # - datastream (the value for that key from the datastreams hash
    def moabify_datastream(name, datastream)
      # TODO: what about content datastream?? won't exist yet but shouldn't go in metadata
      data = datastream.content
      return if data.nil?
      File.write(File.join(metadata_path(self.object.id, self.version), "#{name.to_s}.xml"), data)
    end


    # moabify_resource
    def moabify_resource
      File.write(File.join(metadata_path(self.object.id, self.version), 'resource.rdf'), object.resource.dump(:ttl) )
    end


    # moabify_permissions
    def moabify_permissions
      File.write(File.join(metadata_path(self.object.id, self.version), 'permissions.rdf'), object.permissions.inspect )
    end


    # preserve
    def preserve(resource=false, permissions=false, datastreams=nil)
      create_moab_dirs()
      list = []

      if resource
        moabify_resource
        list << 'resource.rdf'
      end
      
      if permissions
        moabify_permissions
        list << 'permissions.rdf'
      end

      if datastreams.present?
        #object.reload # we must refresh the datastreams list
        datastreams.each do |ds|
          moabify_datastream(ds, object.attached_files[ds])
        end
        list.push(datastreams.map { |item| item << ".xml" }).flatten!
      end

      if @object.object_version.eql?('1')
        create_manifests()
      else
        # This is an update to the existing metadata
        # metadata files cannot be added or deleted after object creation
        update_manifests({:added => {}, :deleted => {}, :modified => {'metadata' => list}})
        # TODO!! Adding assets
      end

    end

    
    # create_manifests
    def create_manifests
      signature_catalog = Moab::SignatureCatalog.new(:digital_object_id => @object.id, :version_id => 0)
      new_version_id = signature_catalog.version_id + 1

      version_inventory = Moab::FileInventory.new(:type => 'version', :version_id => new_version_id, :digital_object_id => @object.id)
      file_group = Moab::FileGroup.new(:group_id=>'metadata').group_from_directory(Pathname.new(metadata_path(@object.id, new_version_id)))
      version_inventory.groups << file_group
      file_group = Moab::FileGroup.new(:group_id=>'content').group_from_directory(Pathname.new(content_path(@object.id, new_version_id)))
      version_inventory.groups << file_group

      version_additions = signature_catalog.version_additions(version_inventory)

      signature_catalog.update(version_inventory, Pathname.new( data_path(@object.id, new_version_id) ))

      file_inventory_difference = Moab::FileInventoryDifference.new
      file_inventory_difference.compare(Moab::FileInventory.new(), version_inventory)

      signature_catalog.write_xml_file(Pathname.new(manifest_path(@object.id, new_version_id)))
      version_inventory.write_xml_file(Pathname.new(manifest_path(@object.id, new_version_id)))
      version_additions.write_xml_file(Pathname.new(manifest_path(@object.id, new_version_id)))
      file_inventory_difference.write_xml_file(Pathname.new(manifest_path(@object.id, new_version_id)))

      manifest_inventory = Moab::FileInventory.new(:type => 'manifests', :digital_object_id=>@object.id, :version_id => new_version_id)
      manifest_inventory.groups << Moab::FileGroup.new(:group_id=>'manifests').group_from_directory(manifest_path(@object.id, new_version_id), recursive=false)
      manifest_inventory.write_xml_file(Pathname.new(manifest_path(@object.id, new_version_id)))

    end

    # update_manifests
    # changes: hash with keys :added, :modified and :deleted. Each is an array of filenames (excluding directory paths)
    def update_manifests(changes)

      last_version_inventory = Moab::FileInventory.new(:type => 'version', :version_id => self.version.to_i-1, :digital_object_id => @object.id)
      last_version_inventory.parse(Pathname.new(File.join(manifest_path(@object.id, self.version.to_i-1),'versionInventory.xml')).read)

      version_inventory = Moab::FileInventory.new(:type => 'version', :version_id => self.version.to_i-1, :digital_object_id => @object.id)
      version_inventory.parse(Pathname.new(File.join(manifest_path(@object.id, self.version.to_i-1),'versionInventory.xml')).read)
      version_inventory.version_id = version_inventory.version_id+1

      changes[:added].keys.each do |type|
        if type.eql?('content')
          path = content_path(@object.id, self.version)
        elsif type.eql?('metadata')
          path = metadata_path(@object.id, self.version)
        end


        changes[:added][type].each do |file|
          file_signature = Moab::FileSignature.new()
          file_signature.signature_from_file(Pathname.new(File.join(path, file)))

          file_instance = Moab::FileInstance.new()
          file_instance.instance_from_file(Pathname.new(File.join(path, file)), Pathname.new(path))

          version_inventory.groups.find {|g| g.group_id == type.to_s }.add_file_instance(file_signature, file_instance)
        end
      end

      changes[:modified].keys.each do |type|
        if type.eql?('content')
          path = content_path(@object.id, self.version)
        elsif type.eql?('metadata')
          path = metadata_path(@object.id, self.version)
        end

        changes[:modified][type].each do |file|
          version_inventory.groups.find {|g| g.group_id == type.to_s }.remove_file_having_path(file)
          file_signature = Moab::FileSignature.new()
          file_signature.signature_from_file(Pathname.new(File.join(path, file)))

          file_instance = Moab::FileInstance.new()
          file_instance.instance_from_file(Pathname.new(File.join(path, file)), Pathname.new(path))

          version_inventory.groups.find {|g| g.group_id == type.to_s }.add_file_instance(file_signature, file_instance)
        end
      end

      changes[:deleted].keys.each do |type|
        if type.eql?('content')
          path = content_path(@object.id, self.version)
        elsif type.eql?('metadata')
          path = metadata_path(@object.id, self.version)
        end

        changes[:modified][type].each do |file|
          add_file_instance(file_signature, file_instance).remove_file_having_path(file)
        end
      end

      signature_catalog = Moab::SignatureCatalog.new(:digital_object_id => @object.id)
      signature_catalog.parse(Pathname.new(File.join(manifest_path(@object.id, self.version.to_i-1),'signatureCatalog.xml')).read)
      version_additions = signature_catalog.version_additions(version_inventory)
      signature_catalog.update(version_inventory, Pathname.new( data_path(@object.id, self.version) ))
      file_inventory_difference = Moab::FileInventoryDifference.new
      file_inventory_difference.compare(last_version_inventory, version_inventory)

      signature_catalog.write_xml_file(Pathname.new(manifest_path(@object.id, self.version)))
      version_inventory.write_xml_file(Pathname.new(manifest_path(@object.id, self.version)))
      version_additions.write_xml_file(Pathname.new(manifest_path(@object.id, self.version)))
      file_inventory_difference.write_xml_file(Pathname.new(manifest_path(@object.id, self.version)))

      manifest_inventory = Moab::FileInventory.new(:type => 'manifests', :digital_object_id=>@object.id, :version_id => self.version)
      manifest_inventory.groups << Moab::FileGroup.new(:group_id=>'manifests').group_from_directory(manifest_path(@object.id, self.version), recursive=false)
      manifest_inventory.write_xml_file(Pathname.new(manifest_path(@object.id, self.version)))

    end


    private

      def make_dir(path)
        begin
          FileUtils.mkdir_p(path) unless File.directory?(path)
        rescue Exception => e
          Rails.logger.error "Unable to create MOAB directory #{path}. Error: #{e.message}"
        end
      end

  end
end
