require 'rdf'
include RDF

module DRI::Formatters
  class Rdf
   
    BASE_URI = "https://repository.dri.ie/catalog/"

    METADATA_FIELDS_MAP = {
     'title' => RDF::DC.title,
     'subject' => RDF::DC.subject,
     'creation_date' => RDF::DC.created,
     'published_date' => RDF::DC.issued,
     'type' => RDF::DC.type,
     'rights' => RDF::DC.rights,
     'language' => RDF::DC.language,
     'description' => RDF::DC.description,
     'creator' => RDF::DC.creator,
     'contributor' => RDF::DC.contributor,
     'publisher' => RDF::DC.publisher,
     'date' => RDF::DC.date,
     'format' => RDF::DC.format,
     'source' => RDF::DC.source,
     'isGovernedBy' => RDF::DC.isPartOf,
     'role_dnr' => RDF::Vocab::MARCRelators.dnr,
     'geographical_coverage' => RDF::DC.spatial,
     'temporal_coverage' => RDF::DC.temporal,
     'institute' => RDF::Vocab::EDM.provider
    }
        
    def initialize(object_doc, options = {})
      fields = options[:fields].presence
      @object_doc = object_doc
      @object_hash = object_doc.extract_metadata(fields)
      build_graph
    end

    def uri
      @uri ||= RDF::URI.new("#{BASE_URI}#{@object_hash['pid']}")
    end

    def ttl_uri
      @ttl_uri ||= RDF::URI.new("#{BASE_URI}#{@object_hash['pid']}.ttl")
    end

    def html_uri
      @html_uri ||= RDF::URI.new("#{BASE_URI}#{@object_hash['pid']}.html")
    end

    def build_graph
      graph << [uri, RDF::DC.hasFormat, RDF::URI("#{uri}.ttl")]
      graph << [uri, RDF::DC.hasFormat, RDF::URI("#{uri}.html")]
      graph << [uri, RDF.type, RDF::FOAF.Document]
      graph << [uri, RDF::DC.title, RDF::Literal.new(
        "Description of '#{@object_hash['metadata']['title'].first}'", language: :en)]
      graph << [uri, FOAF.primaryTopic, RDF::URI("#{BASE_URI}#{@object_hash['pid']}#object")]

      add_licence
      add_formats
      add_metadata
     
      graph
    end

    def add_formats
      format_vocab = RDF::Vocabulary.new("http://www.w3.org/ns/formats/")
      
      graph << [ttl_uri, RDF.type, RDF::Vocab::DCMIType.Text]
      graph << [ttl_uri, RDF.type, format_vocab.Turtle]
      graph << [ttl_uri, RDF::DC.format, RDF::URI("http://purl.org/NET/mediatypes/text/turtle")]
      graph << [ttl_uri, RDF::DC.title, RDF::Literal.new(
        "Description of '#{@object_hash['metadata']['title'].first}' as Turtle (RDF)", language: :en)]

      graph << [html_uri, RDF.type, RDF::Vocab::DCMIType.Text]
      graph << [html_uri, RDF::DC.format, RDF::URI("http://purl.org/NET/mediatypes/text/html")]
      graph << [html_uri, RDF::DC.title, RDF::Literal.new(
        "Description of '#{@object_hash['metadata']['title'].first}' as a web page", language: :en)]
    end

    def add_licence
      licence = @object_doc.licence
      if licence
        value = (licence.name == 'All Rights Reserved') ? licence.name : licence.url
        graph << [uri, RDF::DC.license, value]     
      end
    end

    def add_metadata
      id = "#{BASE_URI}#{@object_hash['pid']}#object"

      metadata = @object_hash['metadata']

      METADATA_FIELDS_MAP.keys.each do |field|
        if metadata[field].present?
          metadata[field].each do |value|
            case field
            when 'isGovernedBy'
              graph << [RDF::URI.new(id), METADATA_FIELDS_MAP[field], RDF::URI("#{BASE_URI}#{value}#collection")]
            when 'geographical_coverage'
              if DRI::Metadata::Transformations.dcmi_box?(value)
                graph << [RDF::URI.new(id), METADATA_FIELDS_MAP[field], RDF::Literal.new(value, datatype: RDF::DC.Box)]
              elsif DRI::Metadata::Transformations.dcmi_point?(value)
                graph << [RDF::URI.new(id), METADATA_FIELDS_MAP[field], RDF::Literal.new(value, datatype: RDF::DC.Point)]
              end
            when 'temporal_coverage'
              if DRI::Metadata::Transformations.dcmi_period?(value)
                graph << [RDF::URI.new(id), METADATA_FIELDS_MAP[field], RDF::Literal.new(value, datatype: RDF::DC.Period)]
              end
            when 'institute'
              graph << [RDF::URI.new(id), METADATA_FIELDS_MAP[field], value['name']]
            else
              graph << [RDF::URI.new(id), METADATA_FIELDS_MAP[field], value]
            end
          end
        end
      end
    end

    def format(options = {})
      output_format = options[:format].presence || :ttl

      output_format == :ttl ? ttl : xml
    end

    def graph
      @graph ||= RDF::Graph.new
    end

    def xml
      graph.to_rdfxml
    end

    def ttl
      graph.to_ttl
    end
  end
end
