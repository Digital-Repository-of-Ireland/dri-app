class ExportsController < ApplicationController

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def new
    @collection = retrieve_object!(params[:id])
  end

  def create
    enforce_permissions!('manage_collection', params[:id])

    begin
      Resque.enqueue(CreateExportJob, params[:id], params[:fields], current_user.email)
    rescue Exception => e
      flash[:alert] = t('dri.flash.error.exporting')
      redirect_to :back
      return
    end

    flash[:notice] = t('dri.flash.notice.exporting')
    redirect_to :back
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