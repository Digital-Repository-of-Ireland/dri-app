class WorkspaceController < ApplicationController

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def index
  end

end