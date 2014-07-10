require 'rack/mime'

class TextSurrogateJob < ActiveFedoraPidBasedJob

  def queue_name
    :text
  end

  def run
    Rails.logger.info "Creating surrogate of #{generic_file_id} asset"

    local_file_info = LocalFile.where("fedora_id LIKE :f AND ds_id LIKE 'content'", { :f => generic_file_id }).order("version DESC").limit(1).to_a
    filename = local_file_info.first.path

    bucket_id = object.batch.nil? ? object.pid : object.batch.pid
    
    ext = Rack::Mime::MIME_TYPES.invert[local_file_info.first.mime_type]
    ext = ext[1..-1] if ext[0] == '.'
    surrogate_filename = "#{generic_file_id}_#{ext}.#{ext}"

    out_file = File.open(filename, "rb")

    storage = Storage::S3Interface.new
    storage.store_surrogate(bucket_id, out_file, surrogate_filename)
  end

end
