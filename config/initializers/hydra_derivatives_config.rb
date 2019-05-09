require 'hydra/derivatives'

Hydra::Derivatives.libreoffice_path = Settings.plugins.libreoffice_path
Hydra::Derivatives::Video::Processor.config.mpeg4.codec = '-vcodec libx264'
