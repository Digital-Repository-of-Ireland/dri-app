module TimelineHelper

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
          query[:q] += " AND #{facet_name}:\"#{facet_value.first}\""
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
    start_date = end_date = ""

    query_string.split(/\s*;\s*/).each do |component|
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

  def get_valid_timeline_count params
    query = get_query params
    count = ActiveFedora::SolrService.count(query[:q], :fq => query[:fq], :defType => "edismax")
    return count
  end

end