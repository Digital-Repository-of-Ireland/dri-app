class UserBackgroundTasksController < ApplicationController

  before_filter :authenticate_user_from_token!
  before_filter :authenticate_user!

  def index
    @tasks = UserBackgroundTask.where(user_id: current_user.id).page(params[:page])
  end

end