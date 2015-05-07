require 'dri/sparql'
require 'dri/sparql/provider'

class LinkedDataJob < ActiveFedoraPidBasedJob

  def queue_name
    :linked_data
  end

  def run
    Rails.logger.info "Retrieving linked data for  #{object.id}"

    uris = []
    object.geographical_coverage.each do |g|
      uris << g if g.start_with?("http")
    end

    uris.each do |uri|
      host = URI(uri).host
      if AuthoritiesConfig[host].present?
        provider = "DRI::Sparql::Provider::#{AuthoritiesConfig[host]['provider']}".constantize.new
        provider.endpoint = AuthoritiesConfig[host]['endpoint']
        provider.retrieve_data(uri)

        object.update_index
      end
    end

  end

end
