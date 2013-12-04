When(/^"(.*?)" has been granted "(.*?)" permissions on "(.*?)"$/) do |user, permission, pid|
  object = ActiveFedora::Base.find(pid, {:cast => true})
  
  if permission == "manage"
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
