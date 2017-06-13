class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: CollectionViewsDatatable.new(view_context)
      end
    end
  end

end
