module PermissionMethods

  private

    def private_metadata_permission(selected_level)
      case selected_level
      when "radio_public"
        return UserGroup::Permissions::PUBLIC_METADATA #"0"
      when "radio_private"
        return UserGroup::Permissions::PRIVATE_METADATA #"1"
      when "radio_inherit"
        return UserGroup::Permissions::INHERIT_METADATA #"-1"
      end
    end

    def master_file_permission(selected_level)
      case selected_level
      when "radio_public"
        return UserGroup::Permissions::PUBLIC_MASTERFILE #"1"
      when "radio_private"
        return UserGroup::Permissions::PRIVATE_MASTERFILE #"0"
      when "radio_inherit"
        return UserGroup::Permissions::INHERIT_MASTERFILE #"-1"
      end
    end

    def update_object_permission_check(param_a, param_b, id)
      if param_a.present? or param_b.present?
        enforce_permissions!("manage_collection", id)
      else
        enforce_permissions!("edit", id)
      end
    end 

end
