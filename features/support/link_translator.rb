module LinkTranslator

  def link_to_id(link_name)

    case link_name

    when /ingest an object/
      "ingest"      

    when /edit an object/
      "edit_record"

    when /sign in/
      "Login"

    when /sign out/
      "Log Out"

    when /cancel my account/
      "Cancel my account"
 
    else "Unknown"
 
    end
  end

end
World(LinkTranslator)
