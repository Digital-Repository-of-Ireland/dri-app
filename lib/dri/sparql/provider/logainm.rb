require 'dri/sparql'

module DRI::Sparql::Provider
  class Logainm

    attr_accessor :endpoint

    def endpoint=(endpoint)
      @endpoint = endpoint
    end

    def retrieve_data(uri)
      return unless DRI::LinkedData.where(source: uri).empty?

      transformed_uri = transform_uri(uri)

      select = "select ?nameEN, ?nameGA, ?lat, ?long
                where { <#{transformed_uri}> <http://xmlns.com/foaf/0.1/name> ?nameGA, ?nameEN
                OPTIONAL { <#{transformed_uri}> <http://geovocab.org/geometry#geometry> ?g . ?g geo:lat ?lat; geo:long ?long }
                filter(lang(?nameEN)=\"en\" && lang(?nameGA)=\"ga\") . }"

      client = DRI::Sparql::Client.new @endpoint
      results = client.query select

      points = []
      names = []
      if results
        results.each_solution do |s|
          north = s[:lat]&.value
          east = s[:long]&.value
          name_en = s[:nameEN]&.value
          name_ga = s[:nameGA]&.value
          names <<  { name_en: name_en, name_ga: name_ga }

          next if north.nil? || east.nil?

          points << DRI::Metadata::Transformations::SpatialTransformations.coords_to_geojson_string(
            [name_en, name_ga],
            "#{east} #{north}",
            nil,
            transformed_uri
          )
        end
      end

      return if names.blank?

      points = dbpedia_lookup(transformed_uri, names) if points.empty?
      return if points.empty?

      linked = DRI::LinkedData.create(
                 source: [uri],
                 resource_type: ['Dataset'],
                 spatial: points
               )

      linked.id
    end

    def dbpedia_lookup(transformed_uri, names)
      select = "select ?lat ?long
                  from <http://dbpedia.org>
                  where {
                  ?s owl:sameAs <#{transformed_uri}>;
                  geo:lat ?lat;
                  geo:long ?long
                 }"

      client = DRI::Sparql::Client.new AuthoritiesConfig['data.dri.ie']['endpoint']
      results = client.query select

      points = []
      if results
        results.each_solution do |s|
          north = s[:lat].value
          east = s[:long].value

          points << DRI::Metadata::Transformations::SpatialTransformations.coords_to_geojson_string(
            [names[0][:name_en], names[0][:name_ga]],
            "#{east} #{north}",
            nil,
            transformed_uri
          )
        end
      end

      points
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
