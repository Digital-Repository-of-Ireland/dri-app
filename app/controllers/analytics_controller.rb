class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    if signed_in? && (current_user.is_admin? || current_user.is_om? || current_user.is_cm?)

      @startdate = params[:startdate] || Date.today.at_beginning_of_month() 
      @enddate = params[:enddate] || Date.today
      respond_to do |format|
        format.html
        format.json do
          render json: MyCollectionsDatatable.new(view_context)
        end
      end
    else
      flash[:error] = t('dri.flash.error.manager_user_permission')
    end
  end

end
