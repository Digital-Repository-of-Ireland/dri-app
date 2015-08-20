class SessionsController < Devise::SessionsController
  after_filter :log_failed_login, :only => :new

  def create
    super
     ::Rails.logger.info "Successful login with email_id : #{request.filtered_parameters["user"]["email"]}"
  end

  private
  def log_failed_login
    ::Rails.logger.info "Failed login with email_id : #{request.filtered_parameters["user"]["email"]}" if failed_login?
  end 

  def failed_login?
    (options = env["warden.options"]) && options[:action] == "unauthenticated"
  end 
end
