module DRI::Derivatives::Services
  class LocalFileSourceFile
    # Retrieves the source
    # @param [ActiveFedora::Base] object the source file is attached to
    # @param [Hash] options
    # @option options [Symbol] :source a method that can be called on the object to retrieve the source file
    # @yield [Tempfile] a temporary source file that has a lifetime of the block
    def self.call(object, options, &block)
      source_name = options.fetch(:source)
      local_file = LocalFile.where(fedora_id: object.id, ds_id: source_name).order("VERSION DESC").take

      yield(local_file)
    end
  end
end
