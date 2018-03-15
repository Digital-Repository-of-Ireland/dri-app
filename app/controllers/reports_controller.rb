class ReportsController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!
  before_action :authenticate_admin!

  def index

    if params[:report].presence == 'stats'
      @mime_type_counts = StatsReport.mime_type_counts
      @total_file_size = StatsReport.total_file_size
    end

    respond_to do |format|
      format.html
      format.json do
        case params[:report].presence
        when 'user'
          render json: UserActivityDatatable.new(view_context)
        when 'object'
          render json: ActivityDatatable.new(view_context)
        when 'fixity'
          render json: FixityDatatable.new(view_context)
        when 'stats'
          render json: CollectionStatsDatatable.new(view_context)
        end
      end
    end
  end
end
