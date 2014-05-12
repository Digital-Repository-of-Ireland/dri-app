module LinkTranslator

  def link_to_id(link_name)

    case link_name

      when /ingest an object/
        "ingest"

      when /edit an object/
        "edit_record"

      when /edit a collection/
        "edit_collection"

      when /edit this record/
        "edit_record"

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

      when /my workspace/
        "workspace"

      when /sign up/
        "signup"

      when /view record/
        "view_record"

      when /browse/
        "browse"

      when /collections/
        "collections"

      when /add to collection/
        "add_to_collection"

      when /download metadata/
        "download_metadata"

      when /download asset/
        "download_asset"

      when /download surrogate/
        "download_surrogate_asset"

      when /admin tasks/
        "admin_tasks"

      when /configure licences/
        "licences"

      when /add new licence/
        "new_licence"

      when /change to en/
        "en"

      when /change to ga/
        "ga"

      when /generate surrogates/
        "surrogates_generate"

      when /publish collection/
        "publish"

      when /publish objects in the collection/
        "publish"

      when /update status/
        "status_update"

      when /accept terms/
        "accept_cookies"

      else "Unknown"

    end
  end

end
World(LinkTranslator)
