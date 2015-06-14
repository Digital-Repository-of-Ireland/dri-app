module TimelineHelper
  include ActionView::Helpers::TextHelper

  def get_valid_timeline_count params
    query = get_query params
    count = ActiveFedora::SolrService.count(query[:q], :fq => query[:fq], :defType => "edismax")
    return count
  end

  def create_timeline_data(response, queried_date="")
    timeline_data = { :timeline => { :type => "default", :date => [] } }
    document_date = nil

    if response.blank?
      timeline_data[:timeline][:headline] = t('dri.application.timeline.headline.no_results')
      timeline_data[:timeline][:text] = t('dri.application.timeline.description.no_results')
    elsif response.size > 120
      timeline_data[:timeline][:headline] = t('dri.application.timeline.headline.too_many_results')
      timeline_data[:timeline][:text] = t('dri.application.timeline.description.too_many_results')
    else
      timeline_data[:timeline][:headline] = t('dri.application.timeline.headline.results_found')
      timeline_data[:timeline][:text] = t('dri.application.timeline.description.results_found')

      response.each_with_index do |document, index|
        document = document.symbolize_keys
        if (!document[:sdateRange].nil?)
          document_date = get_full_date document[:temporal_coverage_tesim], queried_date
          if document_date.empty?
            document_date = document[:sdateRange].first
          end
        end

        timeline_data[:timeline][:date][index] = {}

        unless document_date.nil?
          timeline_data[:timeline][:date][index][:startDate] = document_date.split(' ')[0]
          timeline_data[:timeline][:date][index][:endDate] = document_date.split(' ')[1]

          timeline_data[:timeline][:date][index][:headline] = '<a href="' +  catalog_path(document[:id])+  '">' + document[ActiveFedora::SolrQueryBuilder.solr_name('title', :stored_searchable, type: :string).to_sym].first + '</a>'
          timeline_data[:timeline][:date][index][:text] = truncate(document[ActiveFedora::SolrQueryBuilder.solr_name('description', :stored_searchable, type: :string).to_sym].first, length: 60, separator: ' ')
          timeline_data[:timeline][:date][index][:asset] = {}
          timeline_data[:timeline][:date][index][:asset][:media] = get_cover_image_tm(document)
          timeline_data[:timeline][:date][index][:asset][:thumbnail] = get_cover_image_tm(document)
        end
      end #for-each
    end

    return timeline_data
  end

  private

  def get_full_date dates_array, queried_date=""
    result_date = ""
    date_from = ""
    date_to = ""
    unless queried_date.empty?
      year_from = queried_date.split(" ")[0]
      year_to = queried_date.split(" ")[1]
    end

    dates_array.each do |date|
      if DRI::Metadata::Transformations.dcmi_period? date
        date.split(/\s*;\s*/).each do |component|
          (k,v) = component.split(/\s*=\s*/)
          if k.eql?('start')
            date_from = v
          elsif k.eql?('end')
            date_to = v
          end
        end

        unless date_from.empty?
          if date_to.empty?
            date_to = date_from
          end
          begin
            sdate_str = ISO8601::DateTime.new(date_from).year
            edate_str = ISO8601::DateTime.new(date_to).year

            if (!queried_date.empty?)
              if overlaps?(year_from, sdate_str, year_to, edate_str)
                result_date = "#{ISO8601::DateTime.new(date_from).strftime("%m/%d/%Y")} #{ISO8601::DateTime.new(date_to).strftime("%m/%d/%Y")}"
                break
              end
            else
              result_date = "#{ISO8601::DateTime.new(date_from).strftime("%m/%d/%Y")} #{ISO8601::DateTime.new(date_to).strftime("%m/%d/%Y")}"
              break
            end
          rescue ISO8601::Errors::StandardError
          end
        end
      end
    end

    return result_date
  end

  def get_query params
    query = Hash.new
    query[:q] = query[:fq] = ""
    f_subject_present = false

    if params[:mode] == 'collections'
      query[:fq] += "+#{ActiveFedora::SolrQueryBuilder.solr_name('is_collection', :facetable, type: :string)}:true"
      if !params[:show_subs].eql?('true')
        query[:fq] += " -#{ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"
      end
    else
      query[:fq] += "+#{ActiveFedora::SolrQueryBuilder.solr_name('is_collection', :facetable, type: :string)}:false"
    end

    unless signed_in?
      query[:q] += "#{ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :symbol)}:published"
    end

    unless params[:q].blank?
      query[:q] += " AND #{params[:q]}"
    end

    unless params[:f].blank?
      params[:f].each do |facet_name, facet_value|
        # If the subject temporal is present, parse temporal query
        if ['sdateRange'].include?(facet_name) && params[:year_to].present? && params[:year_from].present?
          f_subject_present = true
          query[:q] += " AND #{facet_name}:[\"-9999 #{(params[:year_from].to_i - 0.5).to_s}\" TO \"#{(params[:year_to].to_i + 0.5).to_s} 9999\"]"
        elsif (facet_name.include?("temporal_coverage")) # subject temporal filter (show record view)
          temporal_q = get_temporal_fq_query(facet_value)
          unless temporal_q.empty?
            f_subject_present = true
            query[:q] << " AND #{temporal_q}"
          end
        else
          facet_value.each do |val|
            query[:q] += " AND #{facet_name}:\"#{val}\""
          end
        end
      end
    end

    # Default subject range query (Any sdateRange value)
    query[:q] += " AND sdateRange:[\"-9999 -9999\" TO \"9999 9999\"]" unless f_subject_present

    # If there is not q parameters then, avoid the query starting with AND
    if query[:q].start_with?(" AND ")
      query[:q] = "#{query[:q][5..-1]}"
    end

    return query
  end

  def get_temporal_fq_query query_string
    fq_query = ""
    start_date = ""
    end_date = ""

    query_string.first.split(/\s*;\s*/).each do |component|
      (k,v) = component.split(/\s*=\s*/)
      if k.eql?('start')
        start_date = v.strip
      elsif k.eql?('end')
        end_date = v.strip
      end
    end

    unless start_date == "" # If date is formatted in DCMI Period, then use the date range Solr field query
      if end_date == ""
        end_date = start_date
      end
      begin
        sdate_str = ISO8601::DateTime.new(start_date).year
        edate_str = ISO8601::DateTime.new(end_date).year
        # In the query, start_date -0.5 and end_date+0.5 are used to include edge cases where the queried dates fall in the range limits
        fq_query = "sdateRange:[\"-9999 #{(sdate_str.to_i - 0.5).to_s}\" TO \"#{(edate_str.to_i + 0.5).to_s} 9999\"]"
      rescue ISO8601::Errors::StandardError => e
      end
    end

    return fq_query
  end

  def get_date_for_display_timeline document_dates, queried_date
    return "" if queried_date.empty?

    result_date = ""
    year_from = queried_date.split(" ")[0]
    year_to = queried_date.split(" ")[1]
    document_dates.each do |date|
      date_from = date.split(" ")[0]
      date_to = date.split(" ")[1]
      if overlaps?(year_from, date_from, year_to, date_to)
        result_date = queried_date
        break
      end
    end

    return result_date
  end

  # I had to add explicit returns and change the url to the static assets
  def get_cover_image_tm(document)
    files_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{document[:id]}\""
    files = ActiveFedora::SolrService.query(files_query)
    file_doc = SolrDocument.new(files.first) unless files.empty?

    if can?(:read, document[:id])
      cover_image = search_image_tm(document, file_doc) unless file_doc.nil?
    end

    cover_image = cover_image_tm(document) if cover_image.nil?

    cover_image = default_image_tm(file_doc) if cover_image.nil?

    return cover_image
  end

  def search_image_tm(document, file_document, image_name = "crop16_9_width_200_thumbnail")
    path = nil

    unless file_document[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].blank?
      format = file_document[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].first
      case format
        when "image"
          path = surrogate_url_tm(document[:id], file_document.id, image_name)
        when "text"
          path = surrogate_url_tm(document[:id], file_document.id, "thumbnail_medium")
      end
    end

    return path
  end

  def default_image_tm(file_document)
    path = "assets/no_image.png"

    unless file_document.nil?
      unless file_document[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].blank?
        format = file_document[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].first

        path = "assets/dri/formats/#{format}.png"

        if Rails.application.assets.find_asset(path).nil?
          path = "assets/no_image.png"
        end
      end
    end

    return path
  end

  def cover_image_tm(document)
    path = nil

    if document[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string).to_sym] && document[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string).to_sym].first
      path = document[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string).to_sym].first
    elsif !document[ActiveFedora::SolrQueryBuilder.solr_name('root_collection', :stored_searchable, type: :string).to_sym].blank?
      collection = root_collection_solr_tm(document)
      if collection[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string)] && collection[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string)].first
        path = collection[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string)].first
      end
    end

    return path
  end

  def root_collection_solr_tm( doc )
    if doc[ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string).to_sym]
      id = doc[ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string).to_sym][0]
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1")
    end
    collection[0]
  end

  def surrogate_url_tm(doc, file_doc, name)

    storage = Storage::S3Interface.new
    url = storage.surrogate_url(doc, file_doc, name)

    return url
  end

  def overlaps?(sdate, other_sdate, edate, other_edate)
    (sdate.to_i - other_edate.to_i) * (other_sdate.to_i - edate.to_i) >= 0
  end

end