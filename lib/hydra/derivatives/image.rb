require 'mini_magick'
module Hydra
  module Derivatives
    class Image < Processor
      def process
        directives.each do |name, args| 
          opts = args.kind_of?(Hash) ? args : {size: args}
          format = opts.fetch(:format, 'png')
          output_file_name = opts.fetch(:datastream, output_file_id(name))
          output_datastream_name = opts.fetch(:datastream, output_file_id(name))
          create_cropped_resized_image(output_file_name, opts[:size], opts[:crop], opts[:gravity], opts[:trim], format) if opts[:crop].present?
          create_resized_image(output_file_name, opts[:size], opts[:trim], format) if (opts[:size].present? && !opts[:crop].present?)
        end
      end

      protected

      def new_mime_type(format)
        MIME::Types.type_for(format).first.to_s
      end

      def create_resized_image(output_datastream, size, trim, format, quality=nil)
        create_image(output_datastream, format, quality) do |xfrm|
          xfrm.combine_options do |c|
            c.resize(size) if size.present?
            if trim.present?
              c.trim
              c.repage.+
            end
          end
        end
      end

      def create_cropped_resized_image(output_datastream, size, crop, gravity, trim, format, quality=nil)
        create_image(output_datastream, format, quality) do |xfrm|
          xfrm.combine_options do |c|
            c.resize(size) if size.present?
            c.gravity(gravity) if gravity.present?
            c.crop(crop) if crop.present?
            if trim.present?
              c.trim
              c.repage.+
            end
          end
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
        bucket_id = object.digital_object.nil? ? object.noid : object.digital_object.noid
        filename = "#{object.id}_#{output_datastream}.#{format}"

        out_file = File.open(output_file, "rb")

        storage = StorageService.new
        storage.store_surrogate(bucket_id, out_file, filename)
        
        File.unlink(output_file)
      end

      def load_image_transformer
        source_file.to_tempfile do |f|
          MiniMagick::Image.read(f.read)
        end
      end
    end
  end
end
