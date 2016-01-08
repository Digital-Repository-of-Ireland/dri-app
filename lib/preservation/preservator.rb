require 'preservation/moab_helpers'

module Preservation
  class Preservator

    include MoabHelpers

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
      File.write(File.join(metadata_path(self.object.id, self.version), 'permissions.rdf'), object.permissions )
    end


    # preserve
    def preserve(resource=false, permissions=false, datastreams=nil)
      create_moab_dirs()

      if resource
        moabify_resource
      end
      
      if permissions
        moabify_permissions
      end

      if datastreams.present?
        object.reload # we must refresh the datastreams list
        datastreams.each do |ds|
          moabify_datastream(ds, object.attached_files[ds])
        end
      end
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
