require "hydra/derivatives/runners/image_derivatives"
require "hydra/derivatives/runners/video_derivatives"

Hydra::Derivatives::ImageDerivatives.class_eval do
  def self.processor_class
    DRI::Derivatives::Processors::Image
  end
end

Hydra::Derivatives::VideoDerivatives.class_eval do
  def self.processor_class
    DRI::Derivatives::Processors::Video::Processor
  end
end


