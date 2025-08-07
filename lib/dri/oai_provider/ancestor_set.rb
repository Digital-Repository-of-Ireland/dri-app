# frozen_string_literal: true
module DRI::OaiProvider
  class AncestorSet < BlacklightOaiProvider::SolrSet

    def self.all
      return if @fields.nil?

      params = { rows: 0, facet: true, 'facet.field' => solr_fields }
      solr_fields.each { |field| params["f.#{field}.facet.limit"] = -1 } # override any potential blacklight limits

      builder = search_service.search_builder.merge(params)
      response = search_service.repository.search(builder)

      sets = []
      sets = sets_from_facets(response.facet_fields) if response.facet_fields

      SetSpec.all.each do |spec|
        sets << new(spec.name)
      end

      sets.empty? ? nil : sets
    end

    def description
      if @label == "collection"
        collection_document['description_tesim'].present? ? collection_document['description_tesim'].join(" ") : ""
      else
        SetSpec.find_by(name: @label)&.description
      end
    end

    def name
      if @label == "collection"
        collection_document['title_tesim'].join(" ")
      else
        SetSpec.find_by(name: @label)&.title
      end
    end

    def solr_filter
      if @label == "collection"
         "#{@solr_field}:\"#{@value.split(':').last}\""
      else
        "{!join from=id to=ancestor_id_ssim}setspec_ssim:#{@label}"
      end
    end

    # Returns array of sets for a solr document, or empty array if none are available.
    def self.sets_for(record)
      return [] if (record.keys & @fields.map { |field| field[:solr_field] }).empty?

      sets = Array.wrap(@fields).map do |field|
        new("#{field[:label]}:#{record.fetch(field[:solr_field], []).reverse.join(':')}")
      end.flatten

      if record.setspec
        record.setspec.each do |spec|
          sets << new("#{spec}")
        end
      end

      sets
    end

    def spec
      if @value
        "#{@label}:#{@value}"
      else
        "#{label}"
      end
    end

    private

    def initialize(spec)
      @label, @value = spec.split(':', 2)
      config = self.class.field_config_for(label)
      @solr_field = config[:solr_field]
      @description = config[:description]
    end

    def collection_document
      @collection_document || load_collection_document
    end

    def load_collection_document
      ::SolrDocument.find(value)
    end
  end
end
