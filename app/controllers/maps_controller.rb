class MapsController < ApplicationController

  before_filter :authenticate_user_from_token!, :only => [:show]
  before_filter :authenticate_user!, :only => [:show]

  def show
    enforce_permissions!("show_digital_object",params[:id])

    @object = retrieve_object!(params[:id])

    geocode = []
    if @object.geocode_point.present?
      @object.geocode_point.each do | point |
        geocode << parse_dcmi(point)
      end
    end

    if @object.geocode_box.present?
      @object.geocode_box.each do | box |
        geocode << parse_dcmi(box)
      end
    end

    data = {}
    data[:location] = geocode
    data[:object] = {}
    data[:object][:name] = @object.title 
    data[:object][:url] = catalog_url(@object.id)

    @locations = data.to_json
  end

  def get

    query = get_query(params)

    num_found = ActiveFedora::SolrService.count(query, :defType => "edismax")
    if (num_found > 0)
      response = ActiveFedora::SolrService.query(query, :defType => "edismax", :rows => num_found)
    else
      response = {}
    end

    # ######## parsing maps coordinates examples
    # ######## TO BE REMOVED BEGIN
    # simple_location = "O'Connel Street"
    # dcmi_location1 = "name=O'Connell Street Lower; north=53.3494; east=-6.26028"
    # dcmi_location2 = "name=Dublin; north=53.3478 ; east=-6.25972"
    # parsed_dcmi1 = parse_dcmi(dcmi_location1)
    # parsed_dcmi2 = parse_dcmi(dcmi_location2)
    # puts parse_dcmi?(simple_location).to_s
    # puts parse_dcmi?(dcmi_location1).to_s
    # puts parsed_dcmi1.inspect
    # puts parsed_dcmi2
    # puts Solrizer.solr_name('geographical_coverage', :stored_searchable, type: :string)
    # ######## TO BE REMOVED END

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


end
