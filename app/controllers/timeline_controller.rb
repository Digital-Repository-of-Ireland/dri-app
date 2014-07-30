class TimelineController < ApplicationController

  def get
    query = ""
    timeline_data = { :timeline => {} }

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

    query += " AND (-#{Solrizer.solr_name('creation_date', :stored_searchable, type: :string)}:unknown"
    query += " AND -#{Solrizer.solr_name('creation_date', :stored_searchable, type: :string)}:\"n/a\")"

    puts "###################"
    puts query
    puts "###################"

    response = ActiveFedora::SolrService.query(query, :defType => "edismax", :rows => "3")

    puts "±±±±±±±±±±±±±±±±±±"
    puts response.inspect
    puts "±±±±±±±±±±±±±±±±±±"

    render :json => timeline_data.to_json
  end
end