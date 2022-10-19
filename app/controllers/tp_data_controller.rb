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

  def show
  end

  def update
  end

  private

end
