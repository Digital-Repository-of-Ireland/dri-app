class ThumbnailJob < IdBasedJob
  include BackgroundTasks::Status

  def queue_name
    :thumbnail
  end

  def run
    with_status_update('thumbnail') { generic_file.create_derivatives(generic_file.label) }
  end

end
