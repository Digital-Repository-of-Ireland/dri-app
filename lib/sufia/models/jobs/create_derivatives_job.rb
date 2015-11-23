class CreateDerivativesJob < ActiveFedoraIdBasedJob
  include BackgroundTasks::Status

  def queue_name
    :derivatives
  end

  def run
    with_status_update('create_derivatives') do
      mime_type = MIME::Types[generic_file.content.mime_type].first
      type = mime_type.respond_to?(:content_type) ? mime_type.content_type : mime_type
      return if type != 'message/external-body' && !generic_file.content.has_content?

      if generic_file.video?
        return unless Sufia.config.enable_ffmpeg
      end
      generic_file.create_derivatives
    end
  end
end
