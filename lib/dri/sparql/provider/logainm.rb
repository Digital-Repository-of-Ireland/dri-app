require 'dri/sparql'

module DRI::Sparql::Provider
  class Logainm

    attr_accessor :endpoint

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
      if results
        results.each_solution do |s|
          north = s[:lat].value
          east = s[:long].value
          points << DRI::Metadata::Transformations::SpatialTransformations.coords_to_geojson_string([s[:nameEN].value,s[:nameGA].value], "#{east} #{north}", nil, transform_uri(uri))
        end
      end

      return unless points.present?

      linked = DRI::LinkedData.new
      linked.source = [uri]
      linked.resource_type = ['Dataset']
      linked.spatial = points
      linked.save

      linked.reload
      linked.id
    end

    def transform_uri(uri)
      host = URI(uri).host
      return uri unless host == 'www.logainm.ie'

      name = uri[%r{[^/]+\z}]
      place_id = File.basename(name,File.extname(name))

      "http://data.logainm.ie/place/#{place_id}"
    end
  end
end
