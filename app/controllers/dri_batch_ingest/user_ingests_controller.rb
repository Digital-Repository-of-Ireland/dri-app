# frozen_string_literal: true
class DRIBatchIngest::UserIngestsController < ApplicationController
  before_action :authenticate_user!
  include DRIBatchIngest::BatchSummaries

  def index
    @ingests = DRIBatchIngest::UserIngest.where(user_id: current_user.id).order(created_at: :desc).page(params[:page]).per(10)
    @batches = user_batches
  end
end
