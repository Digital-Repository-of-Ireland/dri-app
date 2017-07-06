class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    if signed_in? && (current_user.is_admin? || current_user.is_om? || current_user.is_cm?)

      respond_to do |format|
        format.html
        format.json do
          render json: CollectionViewsDatatable.new(view_context)
        end
      end
    else
      flash[:error] = t('dri.flash.error.manager_user_permission')
    end
  end

end
