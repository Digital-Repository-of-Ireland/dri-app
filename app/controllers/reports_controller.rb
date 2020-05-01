class ReportsController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!
  before_action :authenticate_admin!

  def index
    retrieve_stats if params[:report].presence == 'stats'
    @approvers = approvers if params[:report].presence == 'users'

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
        when 'users'
          render json: UsersDatatable.new(user_count, view_context)
        end
      end
    end
  end

  private

  def approvers
    UserGroup::User.find(
      UserGroup::Membership.joins(:group)
      .where("user_group_groups.name = 'cm'")
      .select(:approved_by).distinct.pluck(:approved_by)).collect{ |a| [a.email, a.id] }
  end

  def user_count
    UserGroup::User.count
  end

  def retrieve_stats
    @summary_counts = StatsReport.summary
    @file_type_counts = StatsReport.file_type_counts
    @mime_type_counts = StatsReport.mime_type_counts
    @total_file_size = StatsReport.total_file_size
  end
end
