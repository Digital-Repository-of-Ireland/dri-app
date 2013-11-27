class IndexTextJob < ActiveFedoraPidBasedJob

  def queue_name
    :index_text
  end

  def run
    Rails.logger.info "Creating full text index of #{pid} asset"
  end

end