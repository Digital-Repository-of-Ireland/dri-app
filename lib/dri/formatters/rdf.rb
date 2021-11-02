# frozen_string_literal: true
require 'rdf'
module DRI::Formatters
  class Rdf
    include RDF
    include ActionController::UrlFor
    include Rails.application.routes.url_helpers

    METADATA_FIELDS_MAP = {
      'identifier' => RDF::Vocab::DC.identifier,
      'title' => RDF::Vocab::DC.title,
      'subject' => RDF::Vocab::DC.subject,
      'creation_date' => RDF::Vocab::DC.created,
      'published_date' => RDF::Vocab::DC.issued,
      'type' => RDF::Vocab::DC.type,
      'rights' => RDF::Vocab::DC.rights,
      'language' => RDF::Vocab::DC.language,
      'description' => RDF::Vocab::DC.description,
      'creator' => RDF::Vocab::DC.creator,
      'contributor' => RDF::Vocab::DC.contributor,
      'publisher' => RDF::Vocab::DC.publisher,
      'date' => RDF::Vocab::DC.date,
      'format' => RDF::Vocab::DC.format,
      'source' => RDF::Vocab::DC.source,
      'isGovernedBy' => RDF::Vocab::DC.isPartOf,
      'role_dnr' => RDF::Vocab::MARCRelators.dnr,
      'geographical_coverage' => RDF::Vocab::DC.spatial,
      'temporal_coverage' => RDF::Vocab::DC.temporal,
      'institute' => RDF::Vocab::EDM.provider
    }.freeze

    RELATIONSHIP_FIELDS_MAP = {
      'References' => RDF::Vocab::DC.references,
      'Is Referenced By' => RDF::Vocab::DC.isReferencedBy,
      'Is Related To' => RDF::Vocab::DC.relation,
      'Is Part Of' => RDF::Vocab::DC.isPartOf,
      'Has Part' => RDF::Vocab::DC.hasPart,
      'Is Version Of' => RDF::Vocab::DC.isVersionOf,
      'Has Version' => RDF::Vocab::DC.hasVersion,
      'Is Format Of' => RDF::Vocab::DC.isFormatOf,
      'Has Format' => RDF::Vocab::DC.hasFormat,
      'Source' => RDF::Vocab::DC.source,
      'Has Documentation' => RDF::Vocab::DC.requires,
      'Is Documentation For' => RDF::Vocab::DC.isRequiredBy
    }.freeze

    delegate :env, :request, to: :controller

    attr_reader :controller

    def initialize(controller, object_doc, options = {})
      fields = options[:fields].presence
      @object_doc = object_doc
      @object_hash = object_doc.extract_metadata(fields)
      @with_assets = options[:with_assets].presence
      @controller = controller
      build_graph
    end

    def base_uri
      protocol = request.scheme || 'http'
      "#{protocol}://#{request.host_with_port}"
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
      graph << [uri, RDF::Vocab::DC.hasFormat, RDF::URI("#{uri}.ttl")]
      graph << [uri, RDF::Vocab::DC.hasFormat, RDF::URI("#{uri}.html")]
      graph << [uri, RDF.type, RDF::Vocab::FOAF.Document]
      graph << [uri, RDF::Vocab::DC.title, RDF::Literal.new("Description of '#{@object_hash['metadata']['title'].first}'", language: :en)]
      graph << [uri, RDF::Vocab::FOAF.primaryTopic, RDF::URI("#{uri}#id")]

      add_licence
      add_formats

      add_metadata
      add_relationships
      add_assets if @with_assets

      graph
    end

    def add_assets
      mrss_vocab = RDF::Vocabulary.new("http://search.yahoo.com/mrss/")

      assets = @object_doc.assets

      assets.each do |a|
        id = "#{base_uri}#{file_path(a['id'])}#id"
        graph << [RDF::URI("#{uri}#id"), RDF::Vocab::DC.hasPart, RDF::URI.new(id)]

        graph << [RDF::URI.new(id), RDF.type, file_type(a)]
        graph << [RDF::URI.new(id), RDF::Vocab::FOAF.topic, RDF::URI("#{uri}#id")]
        graph << [RDF::URI.new(id), mrss_vocab.content, RDF::URI("#{base_uri}#{surrogate_path(a['id'])}")]
        graph << [RDF::URI.new(id), RDF::RDFS.label, RDF::Literal.new(a['label_tesim'].first)]
        graph << [RDF::URI.new(id), RDF::Vocab::DC.isPartOf, RDF::URI("#{uri}#id")]
      end
    end

    def surrogate_path(file_id)
      file_download_path(id: file_id, object_id: @object_doc['id'], type: 'surrogate')
    end

    def file_path(file_id)
      object_file_path(id: file_id, object_id: @object_doc['id'])
    end

    def add_formats
      format_vocab = RDF::Vocabulary.new("http://www.w3.org/ns/formats/")

      graph << [ttl_uri, RDF.type, RDF::Vocab::DCMIType.Text]
      graph << [ttl_uri, RDF.type, format_vocab.Turtle]
      graph << [ttl_uri, RDF::Vocab::DC.format, RDF::URI("http://purl.org/NET/mediatypes/text/turtle")]
      graph << [ttl_uri, RDF::Vocab::DC.title, RDF::Literal.new("Description of '#{@object_hash['metadata']['title'].first}' as Turtle (RDF)", language: :en)]

      graph << [html_uri, RDF.type, RDF::Vocab::DCMIType.Text]
      graph << [html_uri, RDF::Vocab::DC.format, RDF::URI("http://purl.org/NET/mediatypes/text/html")]
      graph << [html_uri, RDF::Vocab::DC.title, RDF::Literal.new("Description of '#{@object_hash['metadata']['title'].first}' as a web page", language: :en)]
    end

    def add_licence
      licence = @object_doc.licence
      return unless licence
      value = licence.name == 'All Rights Reserved' ? licence.name : licence.url
      graph << [uri, RDF::Vocab::DC.license, value]
    end

    def add_metadata
      id = "#{uri}#id"

      metadata = @object_hash['metadata']

      graph << [RDF::URI.new(id), RDF.type, RDF::Vocab::DCMIType.Collection] if @object_doc.collection?

      METADATA_FIELDS_MAP.keys.each do |field|
        next if metadata[field].blank?

        metadata[field].each do |value|
          case field
          when 'subject', 'creator', 'contributor'
            subject = sparql_subject(value)
            graph << if subject
                       [RDF::URI.new(id), METADATA_FIELDS_MAP[field], RDF::URI(subject)]
                     else
                       [RDF::URI.new(id), METADATA_FIELDS_MAP[field], value]
                     end
          when 'isGovernedBy'
            graph << [RDF::URI.new(id), METADATA_FIELDS_MAP[field], RDF::URI("#{base_uri}/catalog/#{value}#id")]
          when 'geographical_coverage'
            add_geographical_coverage(id, field, value)
          when 'temporal_coverage'
            add_temporal_coverage(id, field, value)
          when 'institute'
            graph << [RDF::URI.new(id), METADATA_FIELDS_MAP[field], value['name']]
          else
            graph << [RDF::URI.new(id), METADATA_FIELDS_MAP[field], value]
          end
        end
      end

      @object_doc.identifier.each { |ident| graph << [RDF::URI.new(id), METADATA_FIELDS_MAP['identifier'], ident] } if @object_doc.identifier.present?
    end

    def add_relationships
      id = "#{uri}#id"

      relationships = @object_doc.object_relationships
      return if relationships.blank?

      relationships.keys.each do |key|
        relationships[key].each do |relationship|
          relationship_predicate = RELATIONSHIP_FIELDS_MAP[key]
          graph << [RDF::URI.new(id), relationship_predicate, RDF::URI("#{base_uri}/catalog/#{relationship[1]['id']}#id")] if relationship_predicate
        end
      end
    end

    def add_geographical_coverage(id, field, value)
      name = extract_name(value)
      subject = sparql_subject(name)

      graph << if subject
                 [RDF::URI.new(id), METADATA_FIELDS_MAP[field], RDF::URI(subject)]
               else
                 typed_value = if DRI::Metadata::Transformations.dcmi_box?(value)
                                 RDF::Literal.new(value, datatype: RDF::Vocab::DC.Box)
                               elsif DRI::Metadata::Transformations.dcmi_point?(value)
                                 RDF::Literal.new(value, datatype: RDF::Vocab::DC.Point)
                               else
                                 value
                               end

                 [RDF::URI.new(id), METADATA_FIELDS_MAP[field], typed_value]
               end
    end

    def add_temporal_coverage(id, field, value)
      graph << if DRI::Metadata::Transformations.dcmi_period?(value)
                 [RDF::URI.new(id), METADATA_FIELDS_MAP[field], RDF::Literal.new(value, datatype: RDF::Vocab::DC.Period)]
               else
                 [RDF::URI.new(id), METADATA_FIELDS_MAP[field], value]
               end
    end

    def extract_name(value)
      return value unless value.start_with?('name=')

      end_range = value.index(';') || value.length
      value[5..(end_range - 1)]
    end

    def file_type(file)
      if file.text?
        RDF::Vocab::FOAF.Document
      elsif file.image?
        RDF::Vocab::DCMIType.StillImage
      elsif file.audio?
        RDF::Vocab::DCMIType.Sound
      elsif file.video?
        RDF::Vocab::DCMIType.MovingImage
      else
        RDF::Vocab::FOAF.Document
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

    def sparql_subject(value)
      Rails.cache.fetch(value, expires_in: 48.hours) do
        return nil unless AuthoritiesConfig
        provider = DRI::Sparql::Provider::Sparql.new
        provider.endpoint = AuthoritiesConfig['data.dri.ie']['endpoint']

        escaped_value = RDF::NTriples::Writer.escape(value)
        triples = provider.retrieve_data([nil, 'skos:prefLabel', "\"#{escaped_value}\"@en"])

        triples.present? ? triples.first[0] : nil
      end
    end
  end
end
