module ButtonTranslator

  def select_box_to_id(select_name)

    case select_name

    when /ingest methods/
      "ingestmethod"      

    when /object type/
      "ingesttype"

    else "Unknown"
 
    end
  end

end
World(ButtonTranslator)
