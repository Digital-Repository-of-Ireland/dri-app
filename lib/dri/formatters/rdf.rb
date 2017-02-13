require 'rdf'
include RDF

module DRI::Formatters
  module Rdf
   
    DCTERMS = RDF::Vocabulary.new("http://purl.org/dc/terms/")
      
    METADATA_FIELDS_MAP = {
     'title' => RDF::DC.title,
     'subject' => RDF::DC.subject,
     'creation_date' => DCTERMS.created
    }
     #, 'published_date',
     #                              'type', 'rights', 'language', 'description', 'creator',
     #                              'contributor', 'publisher', 'date', 'format', 'source', 'temporal_coverage',
     #                              'geographical_coverage', 'geocode_point', 'geocode_box', 'institute',
     #                              'root_collection_id', 'isGovernedBy', 'ancestor_id', 'ancestor_title', 'role_dnr'].freeze

    def self.xml(object_doc)
      object_hash = format(object_doc, nil)

      graph = RDF::Graph.new


      identifier = object_hash['pid']
      graph << [RDF::URI.new("https://repository.dri.ie/catalog/#{identifier}"), RDF::DC.identifier, identifier]
      metadata = object_hash['metadata']

      METADATA_FIELDS_MAP.keys.each do |field|
        if metadata[field].present?
          metadata[field].each do |value|
            graph << [RDF::URI.new("https://repository.dri.ie/catalog/#{identifier}"), METADATA_FIELDS_MAP[field], value]
          end
        end
      end

      graph.to_rdfxml
    end

    def self.format(object_doc, fields = nil)
      object_doc.extract_metadata(fields)
    end

  end
end
