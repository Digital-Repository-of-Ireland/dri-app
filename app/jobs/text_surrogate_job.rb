require 'rack/mime'

class TextSurrogateJob < IdBasedJob
  include BackgroundTasks::Status

  def queue_name
    :text
  end

  def run
    raise "Incorrect object type" unless generic_file.is_a?(DRI::GenericFile)

    with_status_update('text') do
      Rails.logger.info "Creating surrogate of #{generic_file_id} asset"

      filename = generic_file.path
      bucket_id = generic_file.digital_object.alternate_id

      ext = Rack::Mime::MIME_TYPES.invert[generic_file.mime_type]
      ext = ext[1..-1] if ext[0] == '.'
      ext = 'doc' if ext == 'dot'
      surrogate_filename = "#{generic_file_id}_#{ext}.#{ext}"

      out_file = File.open(filename, "rb")

      storage = StorageService.new
      saved = storage.store_surrogate(bucket_id, out_file, surrogate_filename, MIME::Types.type_for(ext).first.to_s)

      raise "Unable to save text surrogate for #{generic_file_id}" unless saved
    end
  end

end
