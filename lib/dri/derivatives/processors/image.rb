# frozen_string_literal: true
module DRI::Derivatives::Processors
  class Image < Hydra::Derivatives::Processors::Image
    def create_resized_image
      create_image do |xfrm|
        if size
          xfrm.density(density) if density
          xfrm.combine_options do |i|
            i.flatten
            i.resize(size)
          end
        end
      end
    end

    def create_image
      image = selected_layers(load_image_transformer)
      yield(image) if block_given?
      intermediate_path = image.path if directives.key?(:format)
      image.format(directives.fetch(:format))
      image.combine_options do |xfrm|
        combine_options(xfrm)
      end
      write_image(image)
      FileUtils.rm_f(intermediate_path) if intermediate_path
    end

    private

    def combine_options(xfrm)
      if resize_and_pad.present?
        create_resize_and_pad(xfrm)
      else
        xfrm.gravity(gravity) if gravity.present?
        xfrm.crop(crop.to_s) if crop

        if trim.present?
          xfrm.trim
          xfrm.repage('0x0+0+0')
        end
      end
      xfrm.quality(quality.to_s) if quality
    end

    def create_resize_and_pad(xfrm)
      xfrm.resize resize_and_pad
      xfrm.background "rgba(255, 255, 255, 0.0)"
      xfrm.gravity 'Center'
      xfrm.extent resize_and_pad
    end

    def crop
      directives.fetch(:crop, nil)
    end

    def density
      directives.fetch(:density, nil)
    end

    def gravity
      directives.fetch(:gravity, nil)
    end

    def trim
      directives.fetch(:trim, nil)
    end

    def resize_and_pad
      directives.fetch(:resize_and_pad, nil)
    end
  end
end
