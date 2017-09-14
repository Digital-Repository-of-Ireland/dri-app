require 'rack/mime'

class TextSurrogateJob < ActiveFedoraIdBasedJob
  include BackgroundTasks::Status

  def queue_name
    :text
  end

  def run
    with_status_update('text') do
      Rails.logger.info "Creating surrogate of #{generic_file_id} asset"

      filename = generic_file.path

      bucket_id = object.digital_object.nil? ? object.noid : generic_file.noid
    
      ext = Rack::Mime::MIME_TYPES.invert[generic_file.mime_type]
      ext = ext[1..-1] if ext[0] == '.'
      ext = 'doc' if ext == 'dot'
      surrogate_filename = "#{generic_file_id}_#{ext}.#{ext}"

      out_file = File.open(filename, "rb")

      storage = StorageService.new
      saved = storage.store_surrogate(bucket_id, out_file, surrogate_filename)

      raise "Unable to save text surrogate for #{generic_file_id}" unless saved
    end
  end

end
