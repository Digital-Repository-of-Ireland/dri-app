require 'dri/sparql'
require 'dri/sparql/provider'

class LinkedDataJob < ActiveFedoraIdBasedJob

  def queue_name
    :linked_data
  end

  def run
    Rails.logger.info "Retrieving linked data for #{object.id}"

    uris = object.geographical_coverage.select { |g| g.start_with?('http') }
    uris = data_dri_uris if uris.blank?

    uris.each do |uri|
      begin
        host = URI(URI.encode(uri.strip)).host

        if AuthoritiesConfig && AuthoritiesConfig[host].present?
          provider = "DRI::Sparql::Provider::#{AuthoritiesConfig[host]['provider']}".constantize.new
          provider.endpoint=(AuthoritiesConfig[host]['endpoint'])
          linked_data_id = provider.retrieve_data(uri)

          # if linked_data_id
          #   recon_result = ReconciliationResult.new
          #   recon_result.object_id = object.id
          #   recon_result.linked_data_id = linked_data_id
          #   recon_result.save
          # end

          object.update_index
        end
      rescue URI::InvalidURIError
        Rails.logger.info "Bad URI #{uri} in #{object.id}"
      end
    end
  end

  def data_dri_uris
    select = "select ?logainm
              where {
              <https://repository.dri.ie/catalog/#{object.id}#id> dcterms:spatial ?resource .
              ?resource rdfs:seeAlso ?logainm .
              FILTER(regex(str(?logainm), \"logainm\"))
             }"
    client = DRI::Sparql::Client.new AuthoritiesConfig['data.dri.ie']['endpoint']
    results = client.query select

    uris = []
    results.each_solution { |s| uris << s[:logainm].to_s } if results
    uris
  end
end
