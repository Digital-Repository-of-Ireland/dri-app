module DRI::Formatters
  module Json

    def self.format(object_doc, fields = nil)
      object_doc.extract_metadata(fields).to_json
    end

  end
end