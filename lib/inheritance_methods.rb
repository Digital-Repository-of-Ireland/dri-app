module InheritanceMethods

  # Get the earliest ancestor for any inherited attribute
  def get_governing_attribute(object, attribute)
    begin
      value = object.send(attribute)
      return value if value.present?
      return nil if object.governing_collection.nil?
    rescue NoMethodError => e
      flash[:alert] = t('dri.flash.error.invalid_method')
    end
    get_governing_attribute(object.governing_collection, attribute)
  end
  
  # Get the institute manager for any collection or object
  def get_institute_manager(object)
    return object.depositor unless object.governing_collection
      
    get_institute_manager(object.governing_collection)
  end

  def get_read_users_via_group(object)
    users = []
    if object.read_groups.present?
      object.read_groups.each do |group_name|
        if !['public','registered'].include?(group_name)
          group = UserGroup::Group.where(name: group_name)
          group.first.users.each do |user|
            users << [user.first_name, user.second_name, user.email]
          end
        end
      end
      return users
    elsif object.governing_collection.nil?
      return []
    else
      get_read_users_via_group(object.governing_collection)
    end
  end

end
