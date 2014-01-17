class ThumbnailJob < ActiveFedoraPidBasedJob
  def queue_name
    :thumbnail
  end

  def run
    generic_file.create_derivatives
    generic_file.save
  end

end
