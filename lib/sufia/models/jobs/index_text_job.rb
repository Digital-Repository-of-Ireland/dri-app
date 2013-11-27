class IndexTextJob < ActiveFedoraPidBasedJob

  def queue_name
    :index_text
  end

  def run
    Rails.logger.info "Creating full text index of #{generic_file_id} asset"
  end

end