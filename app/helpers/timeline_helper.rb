module TimelineHelper
  include ActionView::Helpers::TextHelper

  def timeline_count(params)
    query = data_query(params)
    ActiveFedora::SolrService.count(query[:q], fq: query[:fq], defType: 'edismax')
  end
  
  def data_query(params)
    query = {}
    query[:q] = ''
    query[:fq] = ''

    f_subject_present = false

    if params[:mode] == 'collections'
      query[:fq] += "+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true"
      unless params[:show_subs] == 'true'
        query[:fq] += " -#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"
      end
    else
      query[:fq] += "+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:false"
    end

    unless signed_in?
      query[:q] += "#{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:published"
    end

    unless params[:q].blank?
      query[:q] += " AND #{params[:q]}"
    end

    unless params[:f].blank?
      params[:f].each do |facet_name, facet_value|
        # If the subject temporal is present, parse temporal query
        if ['sdateRange'].include?(facet_name) && params[:year_to].present? && params[:year_from].present?
          f_subject_present = true
          query[:q] += " AND #{facet_name}:[#{params[:year_from]} TO #{params[:year_to]}]"
        elsif facet_name.include?("temporal_coverage") # subject temporal filter (show record view)
          temporal_q = temporal_fq_query(facet_value)
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
    query[:q] += " AND sdateRange:[-9999 TO 9999]" unless f_subject_present

    # If there is not q parameters then, avoid the query starting with AND
    query[:q] = "#{query[:q][5..-1]}" if query[:q].start_with?(" AND ")

    query
  end

  def temporal_fq_query(query_string)
    fq_query = ''
    start_date = ''
    end_date = ''

    query_string.first.split(/\s*;\s*/).each do |component|
      (k, v) = component.split(/\s*=\s*/)
      if k.eql?('start')
        start_date = v.strip
      elsif k.eql?('end')
        end_date = v.strip
      end
    end

    # If date is formatted in DCMI Period, then use the date range Solr field query
    unless start_date.empty?
      end_date = start_date if end_date.empty?

      begin
        sdate_str = ISO8601::DateTime.new(start_date).year
        edate_str = ISO8601::DateTime.new(end_date).year
        # In the query, start_date -0.5 and end_date+0.5 are used to include edge cases where the queried dates fall in the range limits
        fq_query = "sdateRange:[#{sdate_str} TO #{edate_str}]"
      rescue ISO8601::Errors::StandardError => e
        Rails.logger.error("Timeline helper. Invalid date (non-ISO8601): #{e}")
      end
    end

    fq_query
  end
end
