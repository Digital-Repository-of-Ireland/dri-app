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

      when /^edit$/
        "edit_menu"

      when /^edit a collection$/
        "edit_collection"

      when /^delete a collection$/
        "delete_object"

      when /^delete an object$/
        "delete_object"

      when /^edit this record$/
        "edit_record"

      when /^edit access controls$/
        "edit_access_controls"

      when /^sign in$/
        "login"

      when /^upload XML$/
        "add_object_xml"

      when /^user profile$/
       "view_account"

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
        "configure_download"

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

      when /^manage licence$/
        "manage_licence"

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

      when /^add a cover image$/
        "add_cover_image"

      when /^view asset details$/
        "asset_details"

      when /^view asset tools$/
        "show_asset_tools"

      when /^associate a licence$/
        "manage_licence"

      when /^the workspace page$/
        "workspace"

      when /^add a new collection$/
        "new_collection"

      when /^view the timeline$/
	"timeline_view"

      else "Unknown"

    end
  end

end
World(LinkTranslator)
