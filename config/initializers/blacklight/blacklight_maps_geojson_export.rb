BlacklightMaps::GeojsonExport.class_eval do

  # Render to string the partial for each individual doc.
  # For placename searching, render catalog/map_placename_search partial,
  #  full geojson hash is passed to the partial for easier local customization
  # For coordinate searches (or features with only coordinate data),
  #  render catalog/map_coordinate_search partial
  def render_leaflet_popup_content(geojson_hash, hits=nil)
    if geojson_hash[:properties][placename_property.to_sym].present?
      @controller.render_to_string partial: 'catalog/map_placename_search',
                                   locals: { geojson_hash: geojson_hash, hits: hits }
    else
      @controller.render_to_string partial: 'catalog/map_spatial_search',
                                   locals: { coordinates: geojson_hash[:bbox].presence || geojson_hash[:geometry][:coordinates],
                                             label: label(geojson_hash), hits: hits }
    end
  end

  def label(geojson_hash)
    label = {}
    if geojson_hash[:properties][:geometryCRS].present?
      crs = geojson_hash[:properties][:geometryCRS]
      label[:crs] = crs[:crs]
      label[:projection] = crs[:crs].split('http://www.opengis.net/def/crs/')[1].gsub('/0/', ':')
      label[:coordinates] = crs[:coordinates].join(', ')
    end

    label
  end
end
