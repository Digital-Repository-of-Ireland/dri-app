class MapsController < ApplicationController

  def show
    object = retrieve_object!(params[:id])

    geocode = []
    if object.geocode_point.present?
      object.geocode_point.each do | point |
        p = parse_dcmi(point)
        coords = "#{p[:east]} #{p[:north]}"
        geocode << build_feature_from_coords(p[:name], coords)
      end
    end

    if object.geocode_box.present?
      object.geocode_box.each do | box |
        b = parse_dcmi(box)
        coords = "#{b[:eastlimit]} #{b[:northlimit]} #{b[:westlimit]} #{b[:southlimit]}"
        geocode << build_feature_from_coords(b[:name], coords)
      end
    end

    locations = { type: 'FeatureCollection',
                       features: geocode }

    @geojson_features = locations.to_json
  end

  def get

    query = get_query(params)

    num_found = ActiveFedora::SolrService.count(query, :defType => "edismax")
    if (num_found > 0)
      response = ActiveFedora::SolrService.query(query, :defType => "edismax", :rows => num_found)
    else
      response = {}
    end

    maps_data = create_maps_data(response)

    render :json => maps_data.to_json
  end

  private
  def get_query params
    query = ""

    if params[:mode] == 'collections'
      query += "#{Solrizer.solr_name('file_type', :stored_searchable, type: :string)}:collection"
    else
      query += "-#{Solrizer.solr_name('file_type', :stored_searchable, type: :string)}:collection"
    end

    unless signed_in?
      query += " AND #{Solrizer.solr_name('status', :stored_searchable, type: :symbol)}:published"
    end

    unless params[:q].blank?
      query += " AND #{params[:q]}"
    end

    unless params[:f].blank?
      params[:f].each do |facet_name, facet_value|
        query += " AND #{facet_name}:\"#{facet_value.first}\""
      end
    end

    # geographical coverage exists and it is valid
    query += " AND #{Solrizer.solr_name('geographical_coverage', :stored_searchable, type: :string)}:[* TO *]"
    query += " AND (-#{Solrizer.solr_name('geographical_coverage', :stored_searchable, type: :string)}:unknown"
    query += " AND -#{Solrizer.solr_name('geographical_coverage', :stored_searchable, type: :string)}:\"n/a\")"

    return query
  end

  def parse_dcmi dcmi_location
    parsed_dcmi = {}
    return 'nil' if dcmi_location.nil?

    dcmi_location.split(/\s*;\s*/).each do |component|
      (k,v) = component.split(/\s*=\s*/)
      if (k == 'north' || k == 'east' || k == 'name' || k == 'northlimit' || k == 'southlimit' || k == 'eastlimit' || k == 'westlimit')
        parsed_dcmi[k.to_sym] = v.strip
      end
    end

    if parsed_dcmi.blank?
      return dcmi_location
    end

    if (!parsed_dcmi[:name].blank? && !parsed_dcmi[:north].blank? && !parsed_dcmi[:east].blank?)
      parsed_dcmi[:type] = 'point'
    elsif (!parsed_dcmi[:name].blank? && !parsed_dcmi[:northlimit].blank? && !parsed_dcmi[:southlimit].blank? && !parsed_dcmi[:eastlimit].blank? && !parsed_dcmi[:westlimit].blank?)
      parsed_dcmi[:type] = 'box'
    else
      parsed_dcmi[:type] = 'unknown'
    end

    return parsed_dcmi
  end

  def parse_dcmi? dcmi_location
    parsed_location = parse_dcmi(dcmi_location)
    is_valid = dcmi_location != parsed_location
    if is_valid
      is_valid = is_valid && parsed_location[:type] != 'unknown'
    end
    return is_valid
  end

  def create_maps_data(response)
    maps_data = {}

    maps_data[:num_found] = 0
    maps_data[:location_list] = []
    maps_data[:err_code] = -1

    unless response.blank?
      response.each do |document|
        document = document.symbolize_keys
        location_list = document[Solrizer.solr_name('geographical_coverage', :stored_searchable, type: :string).to_sym]
        location_list.each do |location|
          if (parse_dcmi?(location))
            maps_data[:location_list][maps_data[:num_found]] = {}
            maps_data[:location_list][maps_data[:num_found]][:location] = parse_dcmi(location)
            maps_data[:location_list][maps_data[:num_found]][:object] = {}
            maps_data[:location_list][maps_data[:num_found]][:object][:name] = document[Solrizer.solr_name('title', :stored_searchable, type: :string).to_sym].first
            maps_data[:location_list][maps_data[:num_found]][:object][:url] = catalog_url(document[:id])
            maps_data[:num_found] += 1
          end
        end
      end

      if (maps_data[:num_found] > 0)
        maps_data[:err_code] = 0
      end

    end

    return maps_data
  end

  # build blacklight-maps GeoJSON feature from coordinate data
  # turn bboxes into points for index view so we don't get weird mix of boxes and markers
  def build_feature_from_coords(name, coords, hits = nil)
    geojson_hash = {type: "Feature", geometry: {}, properties: {}}
    if coords.scan(/[\s]/).length == 3 # bbox
      coords_array = coords.split(' ').map { |v| v.to_f }
        geojson_hash[:bbox] = coords_array
        geojson_hash[:geometry][:type] = "Polygon"
        geojson_hash[:geometry][:coordinates] = [[[coords_array[0],coords_array[1]],
                                                  [coords_array[2],coords_array[1]],
                                                  [coords_array[2],coords_array[3]],
                                                  [coords_array[0],coords_array[3]],
                                                  [coords_array[0],coords_array[1]]]]
    elsif coords.match(/^[-]?[\d]*[\.]?[\d]*[ ,][-]?[\d]*[\.]?[\d]*$/) # point
      geojson_hash[:geometry][:type] = "Point"
      if coords.match(/,/)
        coords_array = coords.split(',').reverse
      else
        coords_array = coords.split(' ')
      end
      geojson_hash[:geometry][:coordinates] = coords_array.map { |v| v.to_f }
    else
      Rails.logger.error("This coordinate format is not yet supported: '#{coords}'")
    end
    geojson_hash[:properties] = {}
    geojson_hash[:properties][:placename] = name
    geojson_hash[:properties][:popup] = render_leaflet_popup_content(geojson_hash, hits) if geojson_hash[:geometry][:coordinates]
    geojson_hash[:properties][:hits] = hits.to_i if hits
    geojson_hash
  end 

  # Render to string the partial for each individual doc.
  # For placename searching, render catalog/map_placename_search partial,
  # full geojson hash is passed to the partial for easier local customization
  # For coordinate searches (or features with only coordinate data),
  # render catalog/map_coordinate_search partial
  def render_leaflet_popup_content(geojson_hash, hits=nil)
    render_to_string partial: 'catalog/map_placename_search',
                     locals: { geojson_hash: geojson_hash, hits: hits }
  end

end
