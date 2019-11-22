module UserHelper

  # Return all collection permissions
  # if no user passed in use @current_user
  def collection_permission(user = nil)
    profile_user = user ? user : @current_user
    user_collections = UserCollections.new(user: profile_user)

    Kaminari.paginate_array(user_collections.collections_data).page(params[:page]).per(5)
  end

  def inherited_collection_read_groups(obj)
    return 'restricted' if obj == nil

    if obj.read_groups.empty?
      inherited_collection_read_groups(obj.governing_collection)
    elsif obj.read_groups.first == 'registered'
      return "logged-in"
    elsif obj.read_groups.first == 'public'
      return "public"
    else
      return "restricted"
    end
  end

  def inherited_masterfile_access(obj)
    return 'private' if obj == nil
    return obj.master_file_access unless obj.master_file_access == "inherit" || obj.master_file_access == nil
    inherited_masterfile_access(obj.governing_collection)
  end

end
