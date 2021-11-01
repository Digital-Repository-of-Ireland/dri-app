# frozen_string_literal: true
module DRI::Derivatives::Processors
  class Document < Hydra::Derivatives::Processors::Document
    def self.encode(path, format, outdir)
      execute "#{Hydra::Derivatives.libreoffice_path} --invisible --headless --convert-to #{format} --outdir #{outdir} #{Shellwords.escape(path)}"
    end
  end
end
