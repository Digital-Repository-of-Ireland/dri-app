BlacklightMaps::GeojsonExport.class_eval do

  # Render to string the partial for each individual doc.
  # For placename searching, render catalog/map_placename_search partial,
  #  full geojson hash is passed to the partial for easier local customization
  # For coordinate searches (or features with only coordinate data),
  #  render catalog/map_coordinate_search partial
  def render_leaflet_popup_content(geojson, hits=nil)
    if maps_config.search_mode == 'placename' &&
        geojson[:properties][maps_config.placename_property.to_sym].present?
      @controller.render_to_string partial: 'catalog/map_placename_search',
                                   locals: { geojson_hash: geojson, hits: hits }
    else
      @controller.render_to_string partial: 'catalog/map_spatial_search',
                                   locals: { coordinates: geojson[:bbox].presence || geojson[:geometry][:coordinates],
                                             label: label(geojson), hits: hits }
    end
  end

  def label(geojson)
    label = {}
    if geojson[:properties][:geometryCRS].present?
      crs = geojson[:properties][:geometryCRS]
      label[:crs] = crs[:crs]
      label[:projection] = crs[:crs].split('http://www.opengis.net/def/crs/')[1].gsub('/0/', ':')
      label[:coordinates] = crs[:coordinates].join(', ')
    end

    label
  end
end
