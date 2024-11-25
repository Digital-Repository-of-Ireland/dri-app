require "user_group/engine"

Rails.application.config.to_prepare do
  User = UserGroup::User
  Group = UserGroup::Group
end
