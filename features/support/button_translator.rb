module ButtonTranslator

  def button_to_id(button_name)

    case button_name

    when /ingest metadata/
      "ingest_metadata"      

    when /upload metadata/
      "replace_metadata"

    else "Unknown"
 
    end
  end

end
World(ButtonTranslator)
