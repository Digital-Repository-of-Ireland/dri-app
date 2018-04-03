require 'dri/sparql'

module DRI::Sparql::Provider
  class Logainm

    def endpoint=(endpoint)
      @endpoint = endpoint
    end

    def retrieve_data(uri)
      return unless DRI::LinkedData.where(source: uri).empty?

      select = "select ?nameEN, ?nameGA, ?lat, ?long
                where { <#{transform_uri(uri)}> <http://xmlns.com/foaf/0.1/name> ?nameGA, ?nameEN;
                <http://geovocab.org/geometry#geometry> ?g . ?g geo:lat ?lat; geo:long ?long .
                filter(lang(?nameEN)=\"en\" && lang(?nameGA)=\"ga\") . }"

      client = DRI::Sparql::Client.new @endpoint
      results = client.query select
      
      points = []
      unless results.nil?
        results.each_solution do |s|
          name = "#{s[:nameGA].value}/#{s[:nameEN]}"
          north = s[:lat].value
          east = s[:long].value
          points << DRI::Metadata::Transformations::SpatialTransformations.coords_to_geojson_string(name, "#{east} #{north}")
        end
      end

      return unless points.present?

      linked = DRI::LinkedData.new
      linked.source = [uri]
      linked.resource_type = ['Dataset']
      linked.spatial = points
      linked.save
    end

    def transform_uri(uri)
      host = URI(uri).host

      if host == 'www.logainm.ie'
        name = uri[%r{[^/]+\z}]
        place_id = File.basename(name,File.extname(name))

        "http://data.logainm.ie/place/#{place_id}"
      else
        uri
      end
    end
  end
end
