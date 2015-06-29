class CreateDerivativesJob < ActiveFedoraIdBasedJob
  def queue_name
    :derivatives
  end

  def run
    mime_type = MIME::Types[generic_file.content.mime_type].first
    type = mime_type.respond_to?(:content_type) ? mime_type.content_type : mime_type
    return if type != "message/external-body" && !generic_file.content.has_content?

    if generic_file.video?
      return unless Sufia.config.enable_ffmpeg
    end
    generic_file.create_derivatives
    generic_file.save
  end
end
