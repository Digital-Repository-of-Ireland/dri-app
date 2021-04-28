module PathTranslator

  def path_to(page_name)

    case page_name

      when /^ingest an object$/
        new_ingest_path

      when /^(the )?new Digital Object page$/
        new_ingest_path

      when /^(the )?show Digital Object page for id (.+)$/
        pid = ($2 == "@random")? "dri:o" + @random_pid : $2
        solr_document_path(pid)

      when /^(the )?edit Digital Object page for id (.+)$/
        edit_object_path($2)

      when /^(the )?show page for the collection "(.+)"$/
        solr_document_path($2)

      when /^(the )?edit collection page for id (.+)$/
        edit_collection_path($2)

      when /^(the )?home page$/
        root_path

      when /^(the )?catalog page$?/
        search_catalog_path

      when /^(the )?my collections page$/
        my_collections_index_path

      when /^(the )?my collections page for id (.+)$/
        pid = ($2 == "@random")? "dri:o" + @random_pid : $2
        my_collections_path(pid)

      when /^(the )?user profile page$/
        user_group.profile_path

      when /^sign in$/
        user_group.new_user_session_path

      # This should not be used as we cannot send a delete
      # Instead we should follow the sign out link
      when /^sign out$/
        user_group.destroy_user_session_path

      when /^(the )?User Signin page$/
        user_group.new_user_session_path

      when /^(the )?User Sign up page$/
        user_group.new_user_path

      when /^(the )?new Collection page$/
        new_collection_path

      when /^(the )?view collection page$/
        collections_path

      when /^(the )?my collections page$/
        collections_path

      when /^(the )?my saved search page$/
	blacklight.saved_searches_path

      when /^(the )?show page for the collection$/
        solr_document_path(@collection.id)

      when /^(the )?licence index page$/
        licences_path

      when /^(the )?new licence page$/
        new_licence_path

      when /^(the )?create new collection$/
        new_collection_path

      when /^(the )?new organisation page$/
        new_organisation_path

      when /^(the )?organisations page$/
        organisations_path

      when /^(the )?api docs page$/
        rswag_path

      when /^(the )?workspace page$/
        workspace_path

      when /^(the )?advanced search page$/
        advanced_search_path

      when /^(the )?advanced search page with (\w+) = (.+)$/
        advanced_search_path("#{$2}": $3.strip)

      else
        raise('You specified an invalid path')

    end
  end


  def path_for(type, page, pid)

    case type

      when /object/

        case page
          when /show/
            solr_document_path(pid)
          when /edit/
            id = (pid == "created") ? @obj_pid : pid
            edit_object_path(id)
          when /modify/
            id = (pid == "created") ? @obj_pid : pid
            my_collections_path(id)
        else
            raise('Unknown route')
        end

      when /my collections/
        case page
          when /show/
            my_collections_path(pid)
          when /edit/
            edit_collection_path(pid)
          when /new object/
            new_object_path(collection: pid, method: 'form')
          else
            raise('Unknown route')
        end

      when /collection/
        case page
          when /show/
            solr_document_path(pid)
          when /edit/
            edit_collection_path(pid)
          when /new object/
            new_object_path(collection: pid, method: 'form')
          else
            raise('Unknown route')
        end

      when /metadata/
        case page
          when /upload/
            new_object_path(collection: pid, method: 'upload')
          else
            raise('Unknown route')
        end

      when /asset/
        case page
          when /details/
            object = DRI::DigitalObject.find_by_alternate_id(pid)
            object_file_path(pid, object.generic_files.first.alternate_id)
          else
            raise('Unknown route')
        end

      else
        raise('Unknown route')
    end

  end

end

World(PathTranslator)
