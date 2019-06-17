module DRI::Derivatives::Services
  class PersistS3OutputFile < Hydra::Derivatives::PersistOutputFileService
    def self.call(content, directives)
      bucket_id = directives[:object]
      file_id = directives[:file]

      filename = "#{file_id}_#{directives[:label]}.#{directives[:format]}"

      storage = StorageService.new

      unless content.is_a?(StringIO) || content.is_a?(String)
        storage.store_surrogate(bucket_id, content.path, filename)
        return
      end

      file = Hydra::Derivatives::IoDecorator.new(
        content,
        new_mime_type(directives.fetch(:format)),
        file_id
      )
      temp_file = DRI::Derivatives::Services::TempfileService.new(file)
      temp_file.tempfile do |f|
        storage.store_surrogate(bucket_id, f.path, filename)
      end
    end

   def self.new_mime_type(format)
     case format
     when 'mp4'
       'video/mp4' # default is application/mp4
     when 'webm'
       'video/webm' # default is audio/webm
     else
       MIME::Types.type_for(format).first.to_s
     end
   end
  end
end
