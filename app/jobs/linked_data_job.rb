require 'dri/sparql'
require 'dri/sparql/provider'

class LinkedDataJob < ActiveFedoraIdBasedJob

  def queue_name
    :linked_data
  end

  def run
    Rails.logger.info "Retrieving linked data for #{object.id}"

    uris = object.geographical_coverage.select { |g| g.start_with?('http') }
    uris.each do |uri|
      begin
        host = URI(URI.encode(uri.strip)).host

        if AuthoritiesConfig && AuthoritiesConfig[host].present?
          provider = "DRI::Sparql::Provider::#{AuthoritiesConfig[host]['provider']}".constantize.new
          provider.endpoint=(AuthoritiesConfig[host]['endpoint'])
          provider.retrieve_data(uri)

          object.update_index
        end
      rescue URI::InvalidURIError
        Rails.logger.info "Bad URI #{uri} in #{object.id}"
      end
    end
  end
end
