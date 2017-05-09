require 'rdf'
include RDF

module DRI::Formatters
  class Rdf
   
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
      @with_assets = options[:with_assets].presence
      build_graph
    end

    def base_uri
      protocol = Rails.application.config.action_mailer.default_url_options[:protocol] || 'http'
      "#{protocol}://#{Rails.application.config.action_mailer.default_url_options[:host]}"
    end

    def uri
      @uri ||= RDF::URI.new("#{base_uri}/catalog/#{@object_hash['pid']}")
    end

    def ttl_uri
      @ttl_uri ||= RDF::URI.new("#{uri}.ttl")
    end

    def html_uri
      @html_uri ||= RDF::URI.new("#{uri}.html")
    end
    
    def build_graph
      graph << [uri, RDF::DC.hasFormat, RDF::URI("#{uri}.ttl")]
      graph << [uri, RDF::DC.hasFormat, RDF::URI("#{uri}.html")]
      graph << [uri, RDF.type, RDF::FOAF.Document]
      graph << [uri, RDF::DC.title, RDF::Literal.new(
        "Description of '#{@object_hash['metadata']['title'].first}'", language: :en)]
      graph << [uri, FOAF.primaryTopic, RDF::URI("#{uri}#id")]
       
      add_licence
      add_formats

      add_metadata
      add_assets if @with_assets
     
      graph
    end

    def add_assets
      mrss_vocab = RDF::Vocabulary.new("http://search.yahoo.com/mrss/")

      assets = @object_doc.assets
      
      assets.each do |a| 
        id = "#{base_uri}#{object_file_path(a['id'])}#id"
        graph << [RDF::URI("#{uri}#id"), RDF::DC.hasPart, RDF::URI.new(id)]

        graph << [RDF::URI.new(id), RDF.type, file_type(a)]
        graph << [RDF::URI.new(id), FOAF.topic, RDF::URI("#{uri}#id")]
        graph << [RDF::URI.new(id), mrss_vocab.content, RDF::URI("#{base_uri}#{file_path(a['id'])}")]
        graph << [RDF::URI.new(id), RDF::RDFS.label, RDF::Literal.new(a['label_tesim'])]
        graph << [RDF::URI.new(id), RDF::DC.isPartOf, RDF::URI("#{uri}#id")]
      end
    end

    def file_path(file_id)
      Rails.application.routes.url_helpers.file_download_path(id: file_id, object_id: @object_doc['id'], type: 'surrogate')
    end

    def object_file_path(file_id)
      Rails.application.routes.url_helpers.object_file_path(id: file_id, object_id: @object_doc['id'])
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
      id = "#{uri}#id"

      metadata = @object_hash['metadata']
      
      graph << [RDF::URI.new(id), RDF.type, RDF::Vocab::DCMIType.Collection] if @object_doc.collection?

      METADATA_FIELDS_MAP.keys.each do |field|
        if metadata[field].present?
          metadata[field].each do |value|
            case field
            when 'isGovernedBy'
              graph << [RDF::URI.new(id), METADATA_FIELDS_MAP[field], RDF::URI("#{base_uri}/catalog/#{value}#id")]
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

    def file_type(file)
      if file.text?
        RDF::FOAF.Document
      elsif file.image?
        RDF::Vocab::DCMIType.StillImage
      elsif file.audio?
        RDF::Vocab::DCMIType.Sound
      elsif file.video?
        RDF::Vocab::DCMIType.MovingImage
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
