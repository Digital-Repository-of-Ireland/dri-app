module Hydra
  module Derivatives
    class Document < Processor
      include ShellBasedProcessor

      def self.encode(path, options, output_file)
        format = File.extname(output_file).sub('.', '')
        outdir = File.dirname(output_file)
        execute "#{Hydra::Derivatives.libreoffice_path} --invisible --headless --convert-to #{format} --outdir #{outdir} #{path}"
      end

      def encode_file(dest_path, file_suffix, mime_type, options = { })
        new_output = ''
        Hydra::Derivatives::TempfileService.create(source_file) do |f|
          if mime_type == 'image/jpeg'
            temp_file = File.join(Hydra::Derivatives.temp_file_base, [File.basename(f.path).sub(File.extname(f.path), ''), 'pdf'].join('.'))
            new_output = File.join(Hydra::Derivatives.temp_file_base, [File.basename(temp_file).sub(File.extname(temp_file), ''), file_suffix].join('.'))
            self.class.encode(f.path, options, temp_file)
            self.class.encode(temp_file, options, output_file(file_suffix))
            File.unlink(temp_file)
          else
            self.class.encode(f.path, options, output_file(file_suffix))
            new_output = File.join(Hydra::Derivatives.temp_file_base, [File.basename(f.path).sub(File.extname(f.path), ''), file_suffix].join('.'))
          end
        end
        out_file = File.open(new_output, "rb")
        object.add_file(out_file.read, path: dest_path, mime_type: mime_type)

        bucket_id = object.batch.nil? ? object.id : object.batch.id
        filename = "#{object.id}_#{dest_path}.#{file_suffix}"

        storage = StorageService.new
        storage.store_surrogate(bucket_id, out_file, filename)
    
        File.unlink(out_file)
      end

      def output_file(file_suffix)
        Dir::Tmpname.create(["#{object.id.gsub('/', '_')}-content.", ".#{file_suffix}"], Hydra::Derivatives.temp_file_base){}
      end

      def new_mime_type(format)
        case format
        when 'pdf'
          'application/pdf'
        when 'odf'
          'application/vnd.oasis.opendocument.text'
        when 'docx'
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        when 'xslx'
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        when 'pptx'
          'application/vnd.openxmlformats-officedocument.presentationml.presentation'
        when 'jpg'
          'image/jpeg'
        else
          raise "I don't know about the format '#{format}'"
        end
      end
    end
  end
end
