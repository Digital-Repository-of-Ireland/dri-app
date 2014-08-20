class TimelineController < ApplicationController
  include ApplicationHelper

  def get



    query = get_query(params)

    ######## TO BE REMOVED BEGIN
    puts "###################"
    puts query
    puts "###################"
    ######## TO BE REMOVED END

    response = ActiveFedora::SolrService.query(query, :defType => "edismax", :rows => "50")

    # ######## parsing dates examples
    # ######## TO BE REMOVED BEGIN
    # iso_date = "1986-02-18"
    # w3c_date = "Wed, 09 Feb 1994"
    # dcmi_date = "name=Phanerozoic Eon; end=2009-09-25T16:40+10:00; start=1999-09-25T14:20+10:00; scheme=W3C-DTF;"
    # iso_conv_date = Date.parse(iso_date)
    # w3c_conv_date = Date.parse(w3c_date)
    # parsed_dcmi = parse_dcmi(dcmi_date)
    # puts parse_dcmi?(w3c_date).to_s
    # puts iso_conv_date.inspect
    # puts w3c_conv_date.inspect
    # puts parse_dcmi?(dcmi_date).to_s
    # puts parsed_dcmi.inspect
    # puts Solrizer.solr_name('description', :stored_searchable, type: :string)
    # ######## TO BE REMOVED END

    timeline_data = create_timeline_data(response)

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

    # creation date exists and it is valid
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
        parsed_dcmi[k.to_sym] = Date.parse(v).to_s.gsub(/[-]/, ',')
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

  def create_timeline_data(response)
    timeline_data = { :timeline => { :type => "default", :date => [] } }

    if response.blank?
      timeline_data[:timeline][:headline] = t('dri.application.timeline.headline.no_results')
      timeline_data[:timeline][:text] = t('dri.application.timeline.description.no_results')
    else
      timeline_data[:timeline][:headline] = t('dri.application.timeline.headline.results_found')
      timeline_data[:timeline][:text] = t('dri.application.timeline.description.results_found')

      response.each_with_index do |document, index|
        document = document.symbolize_keys
        creation_date = document[Solrizer.solr_name('creation_date', :stored_searchable, type: :string).to_sym].first
        timeline_data[:timeline][:date][index] = {}

        if parse_dcmi?(creation_date)
          parsed_date = parse_dcmi(creation_date)
          timeline_data[:timeline][:date][index][:startDate] = parsed_date[:start]
          timeline_data[:timeline][:date][index][:endDate] = parsed_date[:end]
        else
          parsed_date = Date.parse(creation_date)
          timeline_data[:timeline][:date][index][:startDate] = parsed_date.to_s.gsub(/[-]/, ',')
          timeline_data[:timeline][:date][index][:endDate] = (parsed_date + 1).to_s.gsub(/[-]/, ',')
        end

        timeline_data[:timeline][:date][index][:headline] = '<a href="' +  catalog_path(document[:id])+  '">' + document[Solrizer.solr_name('title', :stored_searchable, type: :string).to_sym].first + '</a>'
        timeline_data[:timeline][:date][index][:text] = document[Solrizer.solr_name('description', :stored_searchable, type: :string).to_sym].first
        timeline_data[:timeline][:date][index][:asset] = {}
        timeline_data[:timeline][:date][index][:asset][:media] = view_context.cover_image(document)

      end

    end

    return timeline_data
  end


end