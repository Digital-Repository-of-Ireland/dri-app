require 'hydra/derivatives'

Hydra::Derivatives.libreoffice_path = Settings.plugins.libreoffice_path
Hydra::Derivatives.source_file_service = DRI::Derivatives::Services::LocalFileSourceFile
Hydra::Derivatives.output_file_service = DRI::Derivatives::Services::PersistS3OutputFile
Hydra::Derivatives::Video::Processor.config.mpeg4.codec = '-vcodec libx264'
