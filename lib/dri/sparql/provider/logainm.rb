# frozen_string_literal: true
require 'dri/sparql'

module DRI::Sparql::Provider
  class Logainm
    attr_accessor :endpoint

    def retrieve_data(uri)
      return unless DRI::LinkedData.where(source: uri).empty?

      transformed_uri = transform_uri(uri)
      select = logainm_query(transformed_uri)

      client = DRI::Sparql::Client.new @endpoint
      results = client.query select

      names, points = results_to_geojson(results, transformed_uri)
      return if names.blank?

      points = dbpedia_lookup(transformed_uri, names) if points.empty?
      return if points.empty?

      DRI::LinkedData.create(
        source: [uri],
        resource_type: ['Dataset'],
        spatial: points
      ).id
    end

    def dbpedia_lookup(transformed_uri, names)
      client = DRI::Sparql::Client.new AuthoritiesConfig['data.dri.ie']['endpoint']
      results = client.query dbpedia_query(transformed_uri)

      points = []
      results&.each_solution do |s|
        north = s[:lat].value
        east = s[:long].value

        points << geojson_string(names[0][:name_en], names[0][:name_ga], east, north, transformed_uri)
      end

      points
    end

    def transform_uri(uri)
      host = URI(uri).host
      return uri unless host == 'www.logainm.ie'

      name = uri[%r{[^/]+\z}]
      place_id = File.basename(name, File.extname(name))

      "http://data.logainm.ie/place/#{place_id}"
    end

    def logainm_query(transformed_uri)
      "select ?nameEN, ?nameGA, ?lat, ?long
       where { <#{transformed_uri}> <http://xmlns.com/foaf/0.1/name> ?nameGA, ?nameEN
       OPTIONAL { <#{transformed_uri}> <http://geovocab.org/geometry#geometry> ?g . ?g geo:lat ?lat; geo:long ?long }
       filter(lang(?nameEN)=\"en\" && lang(?nameGA)=\"ga\") . }"
    end

    def dbpedia_query(transformed_uri)
      "select ?lat ?long
       from <http://dbpedia.org>
       where {
         ?s owl:sameAs <#{transformed_uri}>;
         geo:lat ?lat;
         geo:long ?long
       }"
    end

    def results_to_geojson(results, transformed_uri)
      names = []
      points = []
      results&.each_solution do |s|
        north = s[:lat]&.value
        east = s[:long]&.value
        name_en = s[:nameEN]&.value
        name_ga = s[:nameGA]&.value

        names << { name_en: name_en, name_ga: name_ga }

        next if north.nil? || east.nil?
        points << geojson_string(name_en, name_ga, east, north, transformed_uri)
      end

      [names, points]
    end

    def geojson_string(name_en, name_ga, east, north, transformed_uri)
      DRI::Metadata::Transformations::SpatialTransformations.coords_to_geojson_string(
        [name_en, name_ga],
        "#{east} #{north}",
        nil,
        transformed_uri
      )
    end
  end
end
