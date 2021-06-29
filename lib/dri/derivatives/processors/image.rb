module DRI::Derivatives::Processors
  class Image < Hydra::Derivatives::Processors::Image

    def create_resized_image
      create_image
    end

    def create_image
      image = selected_layers(load_image_transformer)
      intermediate_path = image.path if directives.key?(:format)
      image.format(directives.fetch(:format))
      image.combine_options do |xfrm|
        xfrm.gravity(gravity) if gravity.present?
        xfrm.crop(crop.to_s) if crop
        if size.present?
          xfrm.flatten
          xfrm.resize(size)
        end
        if trim.present?
          xfrm.trim
          xfrm.repage('0x0+0+0')
        end
        xfrm.quality(quality.to_s) if quality
      end
      write_image(image)
      FileUtils.rm_f(intermediate_path) if intermediate_path
    end

    private

    def crop
      directives.fetch(:crop, nil)
    end

    def gravity
      directives.fetch(:gravity, nil)
    end

    def trim
      directives.fetch(:trim, nil)
    end
  end
end
