# frozen_string_literal: true
class DRIBatchIngest::MediaObjectsController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def show
    @batch = DRIBatchIngest::IngestBatch.find(params[:id])
    @media_object = DRIBatchIngest::MediaObject.find(params[:media_id])

    @files = @media_object.parts.page params[:page]

    @file_info = {}
    @files.each do |f|
      info = {}
      ds = JSON.parse(f['download_spec'])
      info[:title] = ds['file_name']
      info[:size] = ::Filesize.from("#{f.file_size} B").pretty
      info[:url] = ds['url']
      @file_info[f.id] = info
    end
  end
end
