class ActivityController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!
  before_action :authenticate_admin!

  def index
    respond_to do |format|
      format.html
      format.json do
        if params[:report].presence == 'user'
          render json: UserActivityDatatable.new(view_context)
        else
          render json: ActivityDatatable.new(view_context)
        end
      end
    end
  end

end