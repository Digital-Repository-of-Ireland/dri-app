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
      "upload_file"

    when /replace a file/
      "replace_file"

    when /continue/
      "continue"

    when /update language/
      "commit"

    when /add new collection/
      "new_collection"

    when /create a collection/
      "create_new_collection"

    else "Unknown"
 
    end
  end

end
World(ButtonTranslator)
