require "hydra/derivatives/runners/image_derivatives"

Hydra::Derivatives::ImageDerivatives.class_eval do
  def self.processor_class
    DRI::Derivatives::Processors::Image
  end
end

