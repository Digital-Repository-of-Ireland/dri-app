class ExportsController < ApplicationController

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def new
    @collection = retrieve_object!(params[:id])
  end

  def create
    enforce_permissions!('manage_collection', params[:id])

    Resque.enqueue(CreateExportJob, request.base_url, params[:id], params[:fields], current_user.email)
    flash[:notice] = t('dri.flash.notice.exporting')
    redirect_back(fallback_location: root_path)
  rescue Exception
    flash[:alert] = t('dri.flash.error.exporting')
    redirect_back(fallback_location: root_path)
  end

  def show
    enforce_permissions!('manage_collection', params[:id])

    storage = StorageService.new

    bucket = "users.#{Mail::Address.new(current_user.email).local}"
    file = storage.file_url(bucket, "#{params[:export_key]}.csv")
    raise DRI::Exceptions::NotFound unless file

    open(file) do |f|
      send_data(
        f.read,
        filename: File.basename(file),
        type: 'text/csv',
        disposition: 'attachment',
        stream: 'true',
        buffer_size: '4096'
      )
    end
  end

end
