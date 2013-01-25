module FlashTranslator

  def flash_for(message)

    case message

    when /ingestion/
      "Audio object has been successfully ingested"      

    when /invalid metadata/
      "Invalid XML:"

    when /invalid schema/
      "Validation Errors:"

    when /invalid object/
      "Invalid Object:" 

    when /updating metadata/
      "Metadata has been successfully updated"

    when /file upload/
      "File has been successfully uploaded"

    when /invalid file type/
      "The file does not appear to be a valid type"
 
    else "Unknown"
 
    end
  end

end
World(FlashTranslator)
