module ButtonTranslator

  def button_to_id(button_name)

    case button_name

      when /^ingest page$/
        "ingest"

      when /^ingest metadata$/
        "ingest_metadata"

      when /^upload metadata$/
        "dri_upload_metadata_file"

      when /^replace metadata$/
        "replace_metadata"
 
      when /^add an object$/
        "add_object"

      when /^upload XML$/
        "add_object_xml"

      when /^create record$/
        "create_new"

      when /^save changes$/
        "save_edit"

      when /^save search$/
        "save_search"

      when /^set licence$/
        "set_licence"

      when /^delete saved search$/
        "delete_saved_search"

      when /^clear saved search$/
        "clear_saved_search"

      when /^edit a collection$/
        "edit_collection"

      when /^save collection changes$/
        "edit_collection"

      when /^save access controls$/
        "save_access_controls"

      when /^upload a file$/
        "dri_upload_asset_file"

      when /^replace a file$/
        "replace_file"

      when /^add a file$/
        "add_file"

      when /^continue$/
        "continue"

      when /^update language$/
        "commit"

      when /^add new collection$/
        "new_collection"

      when /^create a collection$/
        "create_new_collection"

      when /^add to collection for id (.+)$/
        "collection_toggle_#{$1.parameterize}"

      when /^remove from collection (.+)$/
        "remove_#{$1}"

      when /^set the current collection to (.+)$/
        "set_collection_#{$1}"

      when /^delete collection with id (.+)$/
        "delete_collection_#{$1}"

      when /^accept the end user agreement$/
        "accept_cookies"

      when /^search$/
        "search"

      when /^request access$/
        "request_access"

      when /^approve membership request$/
        "approve_access"

      when /^cancel membership request$/
        "deny_access"

      when /^add an institute$/
        "add_institute"

      when /^add a new institute$/
        "new_institute"

      when /^associate an institute$/
        "associate_inst"

      when /^add a licence$/
        "add_licence"

      when /^save licence$/
        "save_licence"

      when /^generate surrogates$/
        generate_surrogates

      when /^publish collection$/
        publish

      when /^publish objects in collection$/
        publish
      
      when /^update status$/
        "status_update"

      else "Unknown"

    end
  end

end
World(ButtonTranslator)
