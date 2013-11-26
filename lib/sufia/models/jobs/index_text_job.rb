class IndexTextJob < ActiveFedoraPidBasedJob

  def queue_name
    :index_text
  end

  def run
    Rails.logger.info "Creating full text index of #{object_id} asset"
  end

end