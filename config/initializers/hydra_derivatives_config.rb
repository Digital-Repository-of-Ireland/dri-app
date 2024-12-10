ActiveSupport::Reloader.to_prepare do
  Hydra::Derivatives.libreoffice_path = Settings.plugins.libreoffice_path
  Hydra::Derivatives.source_file_service = DRI::Derivatives::Services::LocalFileSourceFile
  Hydra::Derivatives.output_file_service = DRI::Derivatives::Services::PersistS3OutputFile
  Hydra::Derivatives::Processors::Video::Processor.config.mpeg4.codec = '-vcodec libx264'
  Hydra::Derivatives::Processors::Video::Processor.config.size_attributes = 'scale="trunc(oh*a/2)*2:480"'
end
