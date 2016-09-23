class ThumbnailJob < ActiveFedoraIdBasedJob
  include BackgroundTasks::Status
  
  def queue_name
    :thumbnail
  end

  def run
    with_status_update('thumbnail') { generic_file.create_derivatives }
  end

end
