# Controller to generte user reports

class UserReportController < ApplicationController

  before_filter :authenticate_user_from_token!, :only => [:index]
  before_filter :authenticate_user!, :only => [:index]

  def index
    if current_user.is_admin?

     # Get some data
     @audit = PaperTrail::Version.order('created_at ASC').all
     @users = UserGroup::User.all

    end

    respond_to do |format|
      format.html
    end
  end

end

