require 'preservation/moab_helpers'

module Preservation
  class Preservator

    include MoabHelpers

    attr_accessor :base_dir

    def initialize(object_id, version)
     self.base_dir = File.join(local_storage_dir, build_hash_dir(object_id), version_string(version))
    end

    # create_moab_dir
    # Creates MOAB preservation directory structure and saves metadata there
    #
    def create_moab_dirs()
        make_dir self.base_dir
        make_dir File.join(self.base_dir, "metadata")
        make_dir File.join(self.base_dir, "content")
    end

    # moabify_datastream
    # Takes two paramenters
    # - name (datastream and file name)
    # - datastream (the value for that key from the datastreams hash
    def moabify_datastream(name, datastream)
      # TODO: what about content datastream?? won't exist yet but shouldn't go in metadata
      data = datastream.content
      return if data.nil?
      File.write(File.join(self.base_dir, 'metadata', "#{name.to_s}.xml"), data)
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