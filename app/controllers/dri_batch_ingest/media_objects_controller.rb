# frozen_string_literal: true
class DRIBatchIngest::MediaObjectsController < ApplicationController
  include DRIBatchIngest::BatchLookup
  
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def show
    @batch = find_user_batch(params[:id])
    @collection_title = collection_title || @batch.collection_id
    @media_object = @batch.media_objects.find(params[:media_id])
    @files = @media_object.parts.order(:id).page(params[:page])
  end

  private

  def collection_title
    DRI::DigitalObject.find_by_alternate_id(@batch.collection_id)&.title&.first
  end
end
