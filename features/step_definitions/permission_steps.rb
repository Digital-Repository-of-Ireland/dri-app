When(/^"(.*?)" has been granted "(.*?)" permissions(?: on "(.*?)")?$/) do |user, permission, pid|
  object = DRI::Identifier.retrieve_object(pid)

  if permission == "none"
    # do nothing
  elsif permission == "admin"
    user = User.find_by_email(user)
    group_id = UserGroup::Group.find_or_create_by(name: 'admin', description: "Test group", is_locked: true).id
    membership = user.join_group(group_id)
    membership.approved_by = user.id
    membership.save
  elsif permission == "manage"
    if object.manager_users_string.nil?
      object.manager_users_string = User.find_by_email(user).to_s
    else
      object.manager_users_string += ", #{User.find_by_email(user).to_s}"
    end
  elsif permission == "edit"
    if object.edit_users_string.nil?
      object.edit_users_string = User.find_by_email(user).to_s
    else
      object.edit_users_string += ", #{User.find_by_email(user).to_s}"
    end
  end

  object.save
  object.reload
end
