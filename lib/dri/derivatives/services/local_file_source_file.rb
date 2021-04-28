module DRI::Derivatives::Services
  class LocalFileSourceFile
    # Retrieves the source
    # @param [DRI::GenericFile] object the source file is attached to
    # @param [Hash] options
    # @option options [Symbol] :source a method that can be called on the object to retrieve the source file
    # @yield [Tempfile] a temporary source file that has a lifetime of the block
    def self.call(file, options, &block)
      local_file = DRI::GenericFile.find(file.id)

      yield(local_file)
    end
  end
end
