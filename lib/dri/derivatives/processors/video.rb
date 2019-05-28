module DRI::Derivatives::Processors
  module Video
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Processor
      autoload :Config, 'hydra/derivatives/processors/video/config'
    end
  end
end
