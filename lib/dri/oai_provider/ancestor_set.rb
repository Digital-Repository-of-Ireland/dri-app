# frozen_string_literal: true
module DRI::OaiProvider
  class AncestorSet < BlacklightOaiProvider::SolrSet
    def description
      collection_document['description_tesim'].present? ? collection_document['description_tesim'].join(" ") : ""
    end

    def name
      collection_document['title_tesim'].join(" ")
    end

    def solr_filter
      "#{@solr_field}:\"#{@value.split(':').last}\""
    end

    # Returns array of sets for a solr document, or empty array if none are available.
    def self.sets_for(record)
      return [] if (record.keys & @fields.map { |field| field[:solr_field] }).empty?

      Array.wrap(@fields).map do |field|
        new("#{field[:label]}:#{record.fetch(field[:solr_field], []).reverse.join(':')}")
      end.flatten
    end

    private

    def collection_document
      @collection_document || load_collection_document
    end

    def load_collection_document
      ::SolrDocument.find(value)
    end
  end
end
