class TimelineController < ApplicationController

  def get

    timeline_data = { :timeline => {} }

    query = get_query(params)

    puts "###################"
    puts query
    puts "###################"

    response = ActiveFedora::SolrService.query(query, :defType => "edismax", :rows => "150")


    puts "±±±±±±±±±±±±±±±±±±"
    puts response.inspect
    puts "±±±±±±±±±±±±±±±±±±"

    ######## TO BE REMOVED BEGIN
    iso_date = "1986-02-18"
    w3c_date = "Wed, 09 Feb 1994"
    dcmi_date = "name=Phanerozoic Eon; end=2009-09-25T16:40+10:00; start=1999-09-25T14:20+10:00; scheme=W3C-DTF;"
    iso_conv_date = Date.parse(iso_date)
    w3c_conv_date = Date.parse(w3c_date)
    parsed_dcmi = parse_dcmi(dcmi_date)
    puts parse_dcmi?(w3c_date).to_s
    puts iso_conv_date.inspect
    puts w3c_conv_date.inspect
    puts parse_dcmi?(dcmi_date).to_s
    puts parsed_dcmi.inspect
    ######## TO BE REMOVED END

    response.each do |document|
      document = document.symbolize_keys
      puts document[Solrizer.solr_name('creation_date', :stored_searchable, type: :string).to_sym].first
    end
    render :json => timeline_data.to_json
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

    query += " AND #{Solrizer.solr_name('creation_date', :stored_searchable, type: :string)}:[* TO *]"
    query += " AND (-#{Solrizer.solr_name('creation_date', :stored_searchable, type: :string)}:unknown"
    query += " AND -#{Solrizer.solr_name('creation_date', :stored_searchable, type: :string)}:\"n/a\")"

    return query
  end

  def parse_dcmi dcmi_date
    parsed_dcmi = {}
    return 'nil' if dcmi_date.nil?

    dcmi_date.split(/\s*;\s*/).each do |component|
      (k,v) = component.split(/\s*=\s*/)
      if (k == 'start' || k == 'end')
        parsed_dcmi[k.to_sym] = Date.parse(v)
      end
    end

    if parsed_dcmi.blank?
      return dcmi_date
    end

    return parsed_dcmi
  end

  def parse_dcmi? dcmi_date
    return dcmi_date != parse_dcmi(dcmi_date)
  end
end