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
 
    else "Unknown"
 
    end
  end

end
World(FlashTranslator)
