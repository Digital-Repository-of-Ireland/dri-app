require 'mini_magick'
module Hydra
  module Derivatives
    class Image < Processor
      def process
        directives.each do |name, args| 
          opts = args.kind_of?(Hash) ? args : {size: args}
          format = opts.fetch(:format, 'png')
          output_datastream_name = opts.fetch(:datastream, output_datastream_id(name))
       
          create_resized_image(output_datastream_name, opts[:size], format) if opts[:size].present?
          create_cropped_image(output_datastream_name, opts[:gravity], opts[:crop], format) if opts[:crop].present?
        end
      end

      protected

      def new_mime_type(format)
        MIME::Types.type_for(format).first.to_s
      end

      def create_resized_image(output_datastream, size, format, quality=nil)
        create_image(output_datastream, format, quality) do |xfrm|
          xfrm.resize(size) if size.present?
        end
      end

      def create_cropped_image(output_datastream, gravity, crop, format, quality=nil)
        create_image(output_datastream, format, quality) do |xfrm|
          xfrm.gravity(gravity) if gravity.present?
          xfrm.crop(crop) if crop.present?
        end
      end

      def create_image(output_datastream, format, quality=nil)
        xfrm = load_image_transformer
        yield(xfrm) if block_given?
        xfrm.format(format)
        xfrm.quality(quality.to_s) if quality
        write_image(output_datastream, xfrm)
      end

      def write_image(output_datastream, xfrm)
        out_file = nil
        output_file = Dir::Tmpname.create('sufia', Hydra::Derivatives.temp_file_base){}
        xfrm.write(output_file)

        format = xfrm["format"].downcase
        bucket_id = object.batch.nil? ? object.pid : object.batch.pid
        filename = "#{bucket_id}_#{output_datastream}.#{format}"

        out_file = File.open(output_file, "rb")

        storage = Storage::S3Interface.new
        storage.store_surrogate(bucket_id, out_file, filename)
        storage.close
        
        File.unlink(output_file)
      end

      def load_image_transformer
        source_datastream.to_tempfile do |f|
          MiniMagick::Image.read(f.read)
        end
      end
    end
  end
end
