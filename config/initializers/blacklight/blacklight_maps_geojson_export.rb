BlacklightMaps::GeojsonExport.class_eval do

  # build GeoJSON features array
  # determine how to build GeoJSON feature based on config and controller#action
  def build_geojson_features
    features = []
    case @action
      when "index", "map"
        @response_docs.each do |geofacet|
          if facet_mode == "coordinates"
            features.push(build_feature_from_coords(geofacet.value, geofacet.hits))
          else
            features.push(build_feature_from_geojson(geofacet.value, geofacet.hits))
          end
        end
      when "show"
        doc = @response_docs
        return unless doc[geojson_field] || doc[coordinates_field]
        if doc[geojson_field]
          doc[geojson_field].uniq.each do |loc|
            features.push(build_feature_from_geojson(loc))
          end
        elsif doc[coordinates_field]
          doc[coordinates_field].uniq.each do |coords|
            features.push(build_feature_from_coords(coords))
          end
        end
    end
    
    filtered_features(features)
  end

  # build blacklight-maps GeoJSON feature from GeoJSON-formatted data
  # turn bboxes into points for index view so we don't get weird mix of boxes and markers
  def build_feature_from_geojson(loc, hits = nil)
    geojson_hash = JSON.parse(loc).deep_symbolize_keys
    
    if @action != "show" && geojson_hash[:bbox]
      geojson_hash[:geometry][:coordinates] = Geometry::Point.new(Geometry::BoundingBox.new(geojson_hash[:bbox]).find_center).normalize_for_search
      geojson_hash[:geometry][:type] = "Point"
      geojson_hash.delete(:bbox)
    end
    geojson_hash[:properties] ||= {}
    geojson_hash[:properties][:hits] = hits.to_i if hits
    geojson_hash[:properties][:popup] = render_leaflet_popup_content(geojson_hash, hits)
    geojson_hash
  end

  def filtered_features(features)
    features.select { |feature| feature[:properties].dig(:geometryCRS, :crs) == 'http://www.opengis.net/def/crs/EPSG/0/2157' } ||
      features.select { |feature| feature[:properties].dig(:geometryCRS, :crs) == 'http://www.opengis.net/def/crs/EPSG/0/29903' } ||
        features
  end
end
