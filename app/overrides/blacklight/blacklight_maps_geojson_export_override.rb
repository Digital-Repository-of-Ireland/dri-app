BlacklightMaps::GeojsonExport.class_eval do

  def initialize(controller, action, response_docs, options = {})
    @controller = controller
    @controller_params = controller.params.except(:controller, :action, :view, :id, :page, :spatial_search_type, :coordinates).permit!.to_h
    @action = action
    @response_docs = response_docs
    @options = options
    @features = []
  end

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
      coordinates = geojson[:bbox].presence || geojson[:geometry][:coordinates]
      label = label(geojson)

      popup_content = create_popup_content(coordinates, hits, label)
      popup_content += if coordinates.length == 4 
                         link_to_bbox_search(coordinates)
                       else
                         link_to_point_search(coordinates)
                       end
      popup_content
    end
  end

  def create_popup_content(coordinates, hits, label)
    popup_content = "<h5 class=\"geo_popup_heading\">#{coordinates.length == 2 ? coordinates.reverse : coordinates}</br>"
    popup_content += "<small>#{hits} #{I18n.t('blacklight.maps.interactions.item').pluralize(hits)}</small>" if hits
    popup_content += "</h5>"
  
    return popup_content unless label.present?
    
    popup_content += "(<a href=\"#{label[:crs]}\">#{label[:projection]}</a> #{label[:coordinates]})</br>"
    popup_content
  end

  def label(geojson)
    return {} unless geojson[:properties][:geometryCRS].present?
      
    label = {}
    crs = geojson[:properties][:geometryCRS]
    label[:crs] = crs[:crs]
    label[:projection] = crs[:crs].split('http://www.opengis.net/def/crs/')[1].gsub('/0/', ':')
    label[:coordinates] = crs[:coordinates].join(', ')

    label
  end

  # create a link to a spatial search for a set of point coordinates
  # @param point_coords [Array]
  def link_to_point_search(point_coords)
    new_params = @controller_params
    new_params[:spatial_search_type] = 'point'
    new_params[:coordinates] = "#{point_coords[1]},#{point_coords[0]}"  
    new_params[:view] = "list"
    
    "<a href=\"catalog?#{new_params.to_query}\">#{I18n.t('blacklight.maps.interactions.point_search')}</a>"
  end

  # create a link to a bbox spatial search
  # @param bbox [Array]
  def link_to_bbox_search(bbox)
    bbox_coords = bbox.map(&:to_s)
    bbox_search_coords = "[#{bbox_coords[1]},#{bbox_coords[0]} TO #{bbox_coords[3]},#{bbox_coords[2]}]"

    new_params = @controller_params
    new_params[:spatial_search_type] = 'bbox'
    new_params[:coordinates] = bbox_search_coords
    new_params[:view] = "list"

    "<a href=\"catalog?#{new_params.to_query}\">#{I18n.t('blacklight.maps.interactions.bbox_search')}</a>"
  end
end
