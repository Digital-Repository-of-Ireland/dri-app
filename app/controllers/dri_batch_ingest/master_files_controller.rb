# frozen_string_literal: true
class DRIBatchIngest::MasterFilesController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def update
    if params[:master_file][:file_location].present?
      path = params[:master_file].delete(:file_location)
      location = path.start_with?('error:') ? path : "#{Settings.dri.endpoint.chomp('/')}/#{path}"
      params[:master_file][:file_location] = location
    end

    master_file = DRIBatchIngest::MasterFile.find(params[:file_id])
    master_file.update_attributes(update_params)
    master_file.save

    respond_to do |format|
      format.json { head status: :ok }
    end
  end

  private

  def update_params
    params.require(:master_file).permit(:status_code, :file_location)
  end
end
