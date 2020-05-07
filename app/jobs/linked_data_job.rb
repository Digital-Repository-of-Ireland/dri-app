require 'dri/sparql'
require 'dri/sparql/provider'

class LinkedDataJob < IdBasedJob

  def queue_name
    :linked_data
  end

  def run
    Rails.logger.info "Retrieving linked data for #{object.noid}"
    return unless AuthoritiesConfig

    loc_array = object.geographical_coverage + object.coverage
    uris = loc_array.select { |g| g.start_with?('http') } | data_dri_uris
    uris.each do |uri|
      begin
        host = URI(URI.encode(uri.strip)).host

        if AuthoritiesConfig[host].present?
          provider = "DRI::Sparql::Provider::#{AuthoritiesConfig[host]['provider']}".constantize.new
          provider.endpoint=(AuthoritiesConfig[host]['endpoint'])
          provider.retrieve_data(uri)

          object.update_index
        end
      rescue URI::InvalidURIError
        Rails.logger.info "Bad URI #{uri} in #{object.noid}"
      end
    end
  end

  def data_dri_uris
    return [] unless AuthoritiesConfig['data.dri.ie'].present?

    select = "select ?recon
              where {
              <https://repository.dri.ie/catalog/#{object.noid}#id> ?p ?resource .
              ?resource rdfs:seeAlso ?recon }"
    client = DRI::Sparql::Client.new AuthoritiesConfig['data.dri.ie']['endpoint']
    results = client.query select

    uris = []
    results.each_solution do |s|
      uri = s[:recon].to_s
      uris << uri
      DRI::ReconciliationResult.create(object_id: object.noid, uri: uri)
    end
    uris
  end
end
