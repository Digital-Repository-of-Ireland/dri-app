Blacklight::BlacklightMapsHelperBehavior.module_eval do

# create a link to a bbox spatial search
  def link_to_bbox_search bbox_coordinates
    coords_for_search = bbox_coordinates.map { |v| v.to_s }
    link_to(t('blacklight.maps.interactions.bbox_search'),
            url_for(controller: request_controller, action: 'index', only_path: true, spatial_search_type: "bbox",
                               coordinates: "[#{coords_for_search[1]},#{coords_for_search[0]} TO #{coords_for_search[3]},#{coords_for_search[2]}]",
                               view: default_document_index_view_type))
  end

  # create a link to a location name facet value
  def link_to_placename_field field_value, field, displayvalue = nil
    if params[:f] && params[:f][field] && params[:f][field].include?(field_value)
      new_params = params
    else
      new_params = add_facet_params(field, field_value)
    end
    new_params[:view] = default_document_index_view_type
    
    link_to(displayvalue.presence || field_value,
            url_for({controller: request_controller, action: 'index', only_path: true}.merge(
              new_params.except(:id, :spatial_search_type, :coordinates))
            )
          )
  end

  # create a link to a spatial search for a set of point coordinates
  def link_to_point_search point_coordinates
    new_params = params.except(:controller, :action, :view, :id, :spatial_search_type, :coordinates)
    new_params[:spatial_search_type] = "point"
    new_params[:coordinates] = "#{point_coordinates[1]},#{point_coordinates[0]}"
    new_params[:view] = default_document_index_view_type
    link_to(t('blacklight.maps.interactions.point_search'), url_for({controller: request_controller, action: 'index', only_path: true}.merge(new_params)))
  end

  def request_controller
    params[:request_controller].presence || controller_name
  end

end
