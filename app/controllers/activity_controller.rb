class ActivityController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!
  before_action :authenticate_admin!

  def index
    respond_to do |format|
      format.html
      format.json { render json: ActivityDatatable.new(view_context) }
    end
  end

end