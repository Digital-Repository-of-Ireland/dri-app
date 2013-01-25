module LinkTranslator

  def link_to_id(link_name)

    case link_name

    when /ingest an object/
      "ingest"      

    when /edit an object/
      "edit_record"

    when /sign in/
      "login"

    when /sign out/
      "logout"

    when /edit my account/
      "edit_account"

    when /cancel my account/
      "cancel_account"
 
    when /sign up/
      "signup"

     when /view record/
       "View record"

    else "Unknown"
 
    end
  end

end
World(LinkTranslator)
