module ButtonTranslator

  def select_box_to_id(select_name)

    case select_name

    when /ingest methods/
      "ingestmethod"      

    when /object type/
      "ingesttype"

    when /language/
      "user_locale"

    when /ingest collection/
      "ingestcollection"

    when /add to collection/
      "collection_id"

    when /governing collection/
      "dri_model_governing_collection_id"

    else "Unknown"

    end
  end

end
World(ButtonTranslator)
