class CollectionExportsController < ApplicationController

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

#  def new
#    @collection = retrieve_object!(params[:id])
#  end

  def create
    collection_id = params[:collection_id]
    raise DRI::Exceptions::Unauthorized unless CollectionConfig.can_export_full_collection?(collection_id)

    Resque.enqueue(CreateCollectionArchiveJob, collection_id, current_user.email)
    flash[:notice] = t('dri.flash.notice.exporting_full')
    redirect_back(fallback_location: root_path)
  end

  def show
    # TODO this is just copied from exporting metadata, I'm sure the file name won't be a valid one
    storage = StorageService.new

    bucket = "users.#{Mail::Address.new(current_user.email).local}"
    file = storage.file_url(bucket, "#{params[:export_key]}.zip")
    raise DRI::Exceptions::NotFound unless file

    URI.open(file) do |f|
      send_data(
        f.read,
        filename: File.basename(file),
        type: 'application/zip',
        disposition: 'attachment',
        stream: 'true',
        buffer_size: '4096'
      )
    end
  end

end

