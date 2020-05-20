# -*- encoding : utf-8 -*-
require "#{Blacklight.root}/app/controllers/saved_searches_controller"

class SavedSearchesController < ApplicationController
  def index
    @searches = current_user.searches.order('created_at DESC')
    @search_info = retrieve_search_info
    params[:per_page] = params[:per_page] || 9
    @searches = @searches.page(params[:page]).per(params[:per_page])
  end

  private

  def retrieve_search_info
    Hash[
      @searches.map do |search|
      search_count = saved_search_count(search.query_params)
      search_snippets = saved_search_snippet_documents(search.query_params)

      [search.id, { count: search_count, snippets: search_snippets }]
    end
    ]
  end

  def saved_search_snippet_documents(search_params)
    solr_query = saved_search_solr_query(search_params)
    fq = exclude_unwanted_models(search_params)
    Solr::Query.new(
      solr_query,
      10,
      { fq: fq, defType: "edismax", rows: "3" }
    ).query
  end

  def saved_search_count(search_params)
    solr_query = saved_search_solr_query(search_params)
    fq = exclude_unwanted_models(search_params)
    Solr::Query.new(solr_query, 100, { fq: fq, defType: "edismax" }).count
  end

  def saved_search_solr_query(search_params)
    query_params = saved_search_query(search_params[:q])
    query_facets = saved_search_facets(search_params[:f])

    [query_params, query_facets].reject{ |value| value.blank? }.join(" AND ")
  end

  def saved_search_query(search_q)
    search_q.blank? ? "*:*" :  "#{search_q}"
  end

  def saved_search_facets(search_f)
    return "" if search_f.blank?

    search_f.map { |key, value| "#{key}:\"#{value.first}\"" }.join(' AND ')
  end

  def exclude_unwanted_models(user_parameters)
    fq = []
    fq << "-#{Solr::SchemaFields.searchable_symbol('has_model')}:\"DRI::GenericFile\""
    if user_parameters[:mode] == 'collections'
      fq << "+#{Solr::SchemaFields.facet('is_collection')}:true"
      unless user_parameters[:show_subs] == 'true'
        fq << "-#{Solr::SchemaFields.facet('ancestor_id')}:[* TO *]"
      end
    else
      fq << "+#{Solr::SchemaFields.facet('is_collection')}:false"
      if user_parameters[:collection].present?
        fq << "+#{Solr::SchemaFields.facet('root_collection_id')}:\"#{user_parameters[:collection]}\""
      end
    end
    fq << "+#{Solr::SchemaFields.facet('status')}:published"

    fq
  end
end
