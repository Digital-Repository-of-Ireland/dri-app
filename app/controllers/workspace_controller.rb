class WorkspaceController < ApplicationController

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def index
     @tasks_count = UserBackgroundTask.where(user_id: current_user.id).count
  end

end