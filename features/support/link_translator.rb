module LinkTranslator

  def link_to_id(link_name)

    case link_name

    when /ingest an object/
      "ingest"      

    when /edit an object/
      "edit_record"

    when /edit a collection/
      "edit_collection"

    when /sign in/
      "login"

    when /sign out/
      "logout"

    when /reset my password/
      "password_reset"

    when /password confirmation not sent/
      "password_reset_not_sent"

    when /unlock instructions not sent/
      "unlock_not_sent"

    when /view my account/
      "view_account"

    when /edit my account/
      "edit_account"

    when /cancel my account/
      "cancel_account"
 
    when /sign up/
      "signup"

     when /view record/
       "view_record"

     when /my collections/
       "collections"

     when /add to collection/
       "add_to_collection"

     when /download metadata/
       "download_metadata"

     when /download asset/
       "download_asset"

    else "Unknown"
 
    end
  end

end
World(LinkTranslator)
