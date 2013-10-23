When(/^"(.*?)" has been granted "(.*?)" permissions on "(.*?)" with pid "(.*?)"$/) do |user, permission, type, pid|
  object = ActiveFedora::Base.find(pid, {:cast => true})

  if permission == "manage"
    object.manager_users_string += ", #{User.find_by_email(user).to_s}"
  elsif permission == "edit"
    object.edit_users_string += ", #{User.find_by_email(user).to_s}"
  end

  object.save
end
