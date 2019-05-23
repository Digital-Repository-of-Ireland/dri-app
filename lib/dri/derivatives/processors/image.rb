module DRI::Derivatives::Processors
  class Image < Hydra::Derivatives::Processors::Image

    def create_resized_image
      create_image do |xfrm|
        if size
          xfrm.flatten
          xfrm.resize(size)
        end
      end
    end

    def create_image
      image = selected_layers(load_image_transformer)
      image.format(directives.fetch(:format))
      image.combine_options do |xfrm|
        yield(xfrm) if block_given?
        xfrm.gravity(gravity) if gravity.present?
        xfrm.crop(crop.to_s) if crop
        if trim.present?
          xfrm.trim
          xfrm.repage('0x0+0+0')
        end
        xfrm.quality(quality.to_s) if quality
      end
      write_image(image)
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
