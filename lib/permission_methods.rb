module PermissionMethods
  private

    def set_private_metadata_permission(selected_level)
      case selected_level
      when "radio_public"
        return "0"
      when "radio_private"
        return "1"
      when "radio_inherit"
        return "-1"
      end
    end

    def set_master_file_permission(selected_level)
      case selected_level
      when "radio_public"
        return "1"
      when "radio_private"
        return "0"
      when "radio_inherit"
        return "-1"
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