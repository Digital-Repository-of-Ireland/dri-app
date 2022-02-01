# frozen_string_literal: true
module DRI::OaiProvider
  class SolrDocumentWrapper < ::BlacklightOaiProvider::SolrDocumentWrapper
    attr_reader :controller

    def earliest
      builder = search_service.search_builder.merge(fl: solr_timestamp, sort: "#{solr_timestamp} asc", rows: 1)
      response = search_service.repository.search(builder)
      response.documents.first&.timestamp || Time.now
    end

    def latest
      builder = search_service.search_builder.merge(fl: solr_timestamp, sort: "#{solr_timestamp} desc", rows: 1)
      response = search_service.repository.search(builder)
      response.documents.first&.timestamp || Time.now
    end
  end
end
