class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    unless signed_in? && authorized_user?
      flash[:error] = t('dri.flash.error.manager_user_permission')
      return
    end

    @startdate = params[:startdate] || Date.today.at_beginning_of_month
    @enddate = params[:enddate] || Date.today
    @user = params[:user] if current_user.is_admin?

    respond_to do |format|
      format.html
      format.json do
        render json: AnalyticsCollectionsDatatable.new(view_context)
      end
    end
  end

  def show
    unless signed_in? && authorized_user?
      flash[:error] = t('dri.flash.error.manager_user_permission')
      return
    end

    @startdate = params[:startdate] || Date.today.at_beginning_of_month
    @enddate = params[:enddate] || Date.today

    @document = SolrDocument.find(params[:id])
    raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') + " ID: #{params[:id]}" if @document.nil?

    @file_display_type_count = @document.file_display_type_count(published_only: true)

    respond_to do |format|
      format.html
      format.json do
        render json: AnalyticsCollectionDatatable.new(view_context)
      end
    end
  end

  private

    def authorized_user?
      current_user.is_admin? || current_user.is_om? || current_user.is_cm?
    end
end
