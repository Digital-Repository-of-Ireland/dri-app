module ButtonTranslator

  def button_to_id(button_name)

    case button_name

    when /ingest metadata/
      "ingest_metadata"      

    when /upload metadata/
      "replace_metadata"

    when /create record/
      "create_new"

    when /save changes/
      "save_edit"

    when /upload a file/
      "Upload Master File"

    when /replace a file/
      "Replace Master File"

    else "Unknown"
 
    end
  end

end
World(ButtonTranslator)
