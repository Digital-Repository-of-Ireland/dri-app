# frozen_string_literal: true
class DRI::Formatters::Oai < OAI::Provider::Metadata::Format
  include ActionController::UrlFor
  include Rails.application.routes.url_helpers

  delegate :env, :request, to: :controller

  attr_reader :controller

  def initialize
    @prefix = "oai_dri"
    @schema = "https://repository.dri.ie/oai_dri/oai_dri.xsd"
    @namespace = "https://repository.dri.ie/oai_dri/"
    @element_namespace = "dri"
  end

  PREFIXES = {
    dc: {
      title: 'title_tesim',
      description: 'description_tesim',
      creator: 'creator_tesim',
      publisher: 'publisher_tesim',
      subject: 'subject_tesim',
      type: 'type_tesim',
      language: 'language_tesim',
      format: 'file_type_tesim',
      rights: 'rights_tesim'
    },
    dcterms: {
      isPartOf: "collection_id_tesim",
      spatial: "geographical_coverage_tesim",
      temporal: "temporal_coverage_tesim",
      license: lambda do |record|
        licence = record.licence
        licence.present? ? [licence.url || licence.name] : [nil]
      end,
      copyright: lambda do |record|
        copyright = record.copyright
        copyright.present? ? [copyright.url || copyright.name] : [nil]
      end
    },
    edm: {
      provider: lambda { |record| ["Digital Repository of Ireland"] },
      dataProvider: lambda { |record| [record.depositing_institute.try(:name)] }
    }
  }.freeze

  def header_specification
    {
      "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
      "xmlns:dcterms" => "http://purl.org/dc/terms/",
      "xmlns:edm" => "http://www.europeana.eu/schemas/edm/",
      "xmlns:oai_dc" => "http://www.openarchives.org/OAI/2.0/oai_dc/",
      "xmlns:oai_dri" => "https://repository.dri.ie/oai_dri/",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xsi:schemaLocation" => %(
        https://repository.dri.ie/oai_dri/
        https://repository.dri.ie/oai_dri/oai_dri.xsd
      ).gsub(/\s+/, " ")
    }
  end

  def encode(model, record)
    @controller = model.controller

    xml = Builder::XmlMarkup.new

    xml.tag!("#{prefix}:#{element_namespace}", header_specification) do
      PREFIXES.each do |prefix, fields|
        fields.each do |k, v|
          values = v.class == Proc ? v.call(record) : value_for(v, record.to_h, {})

          values.each do |value|
            xml.tag! "#{prefix}:#{k}", value unless value.nil?
          end
        end
      end

      xml.tag! "edm:isShownAt", catalog_url(record.id)
    end

    xml.target!
  end

  def value_for(field, record, _map)
    Array(field).map do |f|
      record[f] || []
    end.flatten.compact
  end
end
