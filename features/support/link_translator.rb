module LinkTranslator

  def link_to_id(link_name)

    case link_name

      when /^ingest page$/
        "ingest"

      when /^ingest an object$/
        "ingest"

      when /^add an object$/
       "add_object"

      when /^edit an object$/
        "edit_record"

      when /^edit a collection$/
        "edit_collection"

      when /^delete a collection$/
        "delete_collection"

      when /^edit this record$/
        "edit_record"

      when /^sign in$/
        "login"

      when /^upload XML$/
        "add_object_xml"

      when /^sign out$/
        "logout"

      when /^reset my password$/
        "password_reset"

      when /^password confirmation not sent$/
        "password_reset_not_sent"

      when /^unlock instructions not sent$/
        "unlock_not_sent"

      when /^view my account$/
        "view_account"

      when /^edit my account$/
        "edit_account"

      when /^cancel my account$/
        "cancel_account"

      when /^my workspace$/
        "workspace"

      when /^my saved search$/
        "saved_search"

      when /^sign up$/
        "signup"

      when /^view record$/
        "view_record"

      when /^browse$/
        "browse"

      when /^collections$/
        "collections"

      when /^add to collection$/
        "add_to_collection"

      when /^download metadata$/
        "download_metadata"

      when /^full metadata$/
        "styled_metadata"

      when /^download asset$/
        "download_master_asset"

      when /^download surrogate$/
        "download_surrogate_asset"

      when /^admin tasks$/
        "admin_tasks"

      when /^configure licences$/
        "licences"

      when /^add new licence$/
        "new_licence"

      when /^change to en$/
        "en"

      when /^change to ga$/
        "ga"

      when /^generate surrogates$/
        "surrogates_generate"

      when /^publish collection$/
        "publish"

      when /^publish objects in the collection$/
        "publish"

      when /^update status$/
        "status_update"

      when /^accept terms$/
        "accept_cookies"

      when /^institutions$/
        "institutions"

      when /^add a new institute$/
        "new_institute"
        
      when /^manage organisations$/
        "manage_organisations"

      when /^manage bookmark$/
        "manage_bookmark"

      when /^remove bookmark$/
        "remove_bookmark"

      when /^clear bookmarks$/
        "clear_bookmarks"

      when /^clear saved search$/
        "clear_saved_search"

      when /^upload a file$/
        "upload_file"

      when /^replace a file$/
        "replace_file"

      when /^add a file$/
        "add_file"

      else "Unknown"

    end
  end

end
World(LinkTranslator)
