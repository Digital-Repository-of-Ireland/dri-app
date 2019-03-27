module DRI::Derivatives::Processors
  class Image < Hydra::Derivatives::Processors::Image

    def create_image
      xfrm = selected_layers(load_image_transformer)
      yield(xfrm) if block_given?
      xfrm.gravity(gravity) if gravity.present?
      xfrm.crop(crop.to_s) if crop
      if trim.present?
        xfrm.trim
        xfrm.repage('0x0+0+0')
      end
      xfrm.format(directives.fetch(:format))
      xfrm.quality(quality.to_s) if quality
      write_image(xfrm)
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
