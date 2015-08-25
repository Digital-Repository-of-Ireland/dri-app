class ThumbnailJob < ActiveFedoraIdBasedJob
  def queue_name
    :thumbnail
  end

  def run
    generic_file.create_derivatives
  end

end
