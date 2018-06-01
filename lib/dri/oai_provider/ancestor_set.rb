module DRI::OaiProvider
  class AncestorSet < BlacklightOaiProvider::SolrSet

    def description
      collection_document['description_tesim'].join(" ")
    end

    def name
      collection_document['title_tesim'].join(" ")
    end

    # Returns array of sets for a solr document, or empty array if none are available.
    def self.sets_for(record)
      Array.wrap(@fields).map do |field|
        record.fetch(field[:solr_field], []).map do |value|
          new("#{field[:label]}:#{value}")
        end
      end.flatten
    end

    private

    def collection_document
      @collection_document || load_collection_document
    end

    def load_collection_document
      ActiveFedora::SolrService.query("id:#{value}").first
    end

  end
end
