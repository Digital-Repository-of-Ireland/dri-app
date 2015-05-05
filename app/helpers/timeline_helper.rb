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

  def get_valid_timeline_count params
    query = get_query params
    count = ActiveFedora::SolrService.count(query[:q], :fq => query[:fq], :defType => "edismax")
    return count
  end

end