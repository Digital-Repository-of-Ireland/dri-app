module PathTranslator

  def path_to(page_name)

    case page_name

      when /ingest an object/
        new_ingest_path

      when /new Digital Object page/
        new_ingest_path

      when /show Digital Object page for id (.+)/
        pid = ($1 == "@random")? "dri:o" + @random_pid : $1
        catalog_path(pid)

      when /edit Digital Object page for id (.+)/
        edit_object_path($1)

      when /show page for the collection "(.+)"/
        catalog_path($1)

      when /edit collection page for id (.+)/
        edit_collection_path($1)

      when /the home page/
        root_path

      when /sign in/
        user_group.new_user_session_path

      # This should not be used as we cannot send a delete
      # Instead we should follow the sign out link
      when /sign out/
        user_group.destroy_user_session_path

      when /User Signin page/
        user_group.new_user_session_path

      when /User Sign up page/
        user_group.new_user_path

      when /new Collection page/
        new_collection_path

      when /view collection page/
        collections_path

      when /my collections page/
        collections_path

      when /my saved search page/
        saved_searches_path

      when /show page for the collection/
        catalog_path(@collection.id)

      when /licence index page/
        licences_path

      when /new licence page/
        new_licence_path

      else
        raise('You specified an invalid path')

    end
  end


  def path_for(type, page, pid)

    case type

      when /object/

        case page
          when /show/
            catalog_path(pid)
          when /edit/
            edit_object_path(pid)
          else
            raise('Unknown route')
        end

      when /collection/
        case page
          when /show/
            catalog_path(pid)
          when /edit/
            edit_collection_path(pid)
          else
            raise('Unknown route')
        end

      else
        raise('Unknown route')
    end

  end

end

World(PathTranslator)
