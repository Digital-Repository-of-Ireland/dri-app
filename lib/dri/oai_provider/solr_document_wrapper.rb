# frozen_string_literal: true
module DRI::OaiProvider
  class SolrDocumentWrapper < ::BlacklightOaiProvider::SolrDocumentWrapper
    attr_reader :controller

    def earliest
      builder = @controller.search_builder.merge(fl: solr_timestamp, sort: "#{solr_timestamp} asc", rows: 1)
      response = @controller.repository.search(builder)
      response.documents.present? ? response.documents.first.timestamp : Time.now.iso8601
    end

    def latest
      builder = @controller.search_builder.merge(fl: solr_timestamp, sort: "#{solr_timestamp} desc", rows: 1)
      response = @controller.repository.search(builder)
      response.documents.present? ? response.documents.first.timestamp : Time.now.iso8601
    end
  end
end
