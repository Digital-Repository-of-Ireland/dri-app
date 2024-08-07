module DeviseRequestSpecHelper

  include Warden::Test::Helpers

  def sign_in(resource_or_scope, resource = nil)
    resource ||= resource_or_scope
    scope = Devise::Mapping.find_scope!(resource_or_scope)
    login_as(resource, scope: scope)
  end

  def sign_out(resource_or_scope)
    scope = Devise::Mapping.find_scope!(resource_or_scope)
    logout(scope)
  end

  def sign_out_all
    # https://github.com/wardencommunity/warden/wiki/testing
    # logout without scope should log out all users
    logout
    # User.all.each do |user|
    #   sign_out(user)
    # end
  end

end
