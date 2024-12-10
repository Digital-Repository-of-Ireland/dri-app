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

Hydra::Derivatives::DocumentDerivatives.class_eval do
  def self.processor_class
    DRI::Derivatives::Processors::Document
  end
end