require 'rsolr'
require 'blacklight/catalog'

class TpDataController < ApplicationController
  before_action :authenticate_user_from_token!, only: [:index, :download]
  before_action :authenticate_user!, only: :index
  before_action :read_only, only: [:update]

  def index
  end

  def create
    raise DRI::Exceptions::BadRequest unless params[:id].present?
    enforce_permissions!('manage_collection', params[:id])
    raise Blacklight::AccessControls::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless can? :manage_collection, params[:id]

    # Get the Transcribathon Story ID
    story_id = "151153" # TODO: Remove hardcoding, figure out where do we get this

    # queue FetchTbData background job
    Resque.enqueue(FetchTpDataJob, params[:id], story_id)

    # reload and flash success message
    flash[:success] = t('dri.flash.notice.tp_request_submitted')
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  def edit
    raise DRI::Exceptions::BadRequest unless params[:id].present?
    enforce_permissions!('manage_collection', params[:id])
    raise Blacklight::AccessControls::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless can? :manage_collection, params[:id]

    @document = SolrDocument.find(params[:id])
    @presenter = DRI::ObjectInCatalogPresenter.new(@document, view_context)
    @assets = @document.assets(with_preservation: false, ordered: true)
    @story = TpStory.where(dri_id: params[:id]).first
    @items = TpItem.where(story_id: @story.story_id).order(:item_id)
    @earliest_item = TpItem.where.not(start_date: nil).order(start_date: :asc).first
    @latest_item = item = TpItem.where.not(end_date: nil).order(start_date: :desc).first
    @early_items = TpItem.where(start_date: @earliest_item.start_date)
    @late_items = TpItem.where(end_date: @latest_item.end_date)
 
    # Get all dates for this object id (DRI id)
    # parse dates and get earliest and latest date
    # make an array of all other dates
    # Some initial possible variables below, these to be passed to the view
    @firstdate = "1890-01-01" # the earliest start date in any of the items
    @lastdate = "1894-04-20" # the latest end date in any of the items (or lates start date if no end dates
    @alldates = [["1890-01-01","1890-01-05"], ["1890-03-16", ""], ["1894-02-03", "1894-04-20"]] # a list of all start & end dates across all items

  end

  private

end
