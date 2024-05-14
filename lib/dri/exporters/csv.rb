# frozen_string_literal: true
require 'csv'

module DRI::Exporters
  class Csv
    include Rails.application.routes.url_helpers

    METADATA_FIELDS_MAP = {
      'title' => 'Title',
      'subject' => 'Subjects',
      'creation_date' => 'Creation Date',
      'published_date' => 'Published Date',
      'type' => 'Type',
      'rights' => 'Rights',
      'language' => 'Language',
      'description' => 'Description',
      'creator' => 'Creator',
      'contributor' => 'Contributor',
      'publisher' => 'Publisher',
      'date' => 'Date',
      'format' => 'Format',
      'source' => 'Source',
      'status' => 'Status',
      'isGovernedBy' => 'Collection',
      'role_dnr' => 'Donor',
      'geographical_coverage' => 'Subjects (Places)',
      'temporal_coverage' => 'Subjects (Temporal)',
      'institute' => 'Organisation',
      'identifiers' => 'Identifiers',
      'relations' => 'Relations'
    }.freeze

    def initialize(base_url, object_doc, options = {})
      fields = options.dig(:fields)
      @with_assets = options[:with_assets].presence
      @request_fields = fields || METADATA_FIELDS_MAP.keys
      @base_url = base_url
      @object_doc = object_doc
      @object = DRI::DigitalObject.find_by_alternate_id(object_doc['id'])
    end

    def format
      titles = title_row

      csv_string = CSV.generate do |csv|
        csv << titles
        csv << object_row
      end

      csv_string
    end

    def title_row
      titles = ['Id']
      @request_fields.each { |k| titles << METADATA_FIELDS_MAP[k] }
      titles << 'Licence'
      titles << 'Assets' if @with_assets.present?
      titles << 'Url'

      titles
    end

    def object_row
      row = [@object_doc['id']]
      @request_fields.each do |key|
        field = map_field(key)
        value = field.is_a?(Array) ? field.join('|') : field
        row << value || ''
      end
      row << licence
      row << assets if @with_assets.present?
      row << url
      row
    end

    def map_field(key)
      if key == 'identifiers'
        @object_doc.identifier
      elsif key == 'status'
        @object_doc.status
      elsif key == 'relations'
        relation
      else
        @object_doc[Solrizer.solr_name(key, :stored_searchable, type: :string)]
      end
    end

    def assets
      assets = @object_doc.assets
      asset_column = []
      assets.each { |a| asset_column << file_url(a['id']) }
      asset_column.join('|')
    end

    def file_url(file_id)
      File.join(@base_url, file_download_path(
        id: file_id,
        object_id: @object_doc['id'],
        type: 'surrogate'
      ))
    end

    def licence
      licence = @object_doc.licence
      return '' if licence.nil?

      licence.name == 'All Rights Reserved' ? licence.name : licence.url
    end

    def copyright
      copyright = @object_doc.copyright
      return '' if copyright.nil?

      copyright.name == 'In Copyright' ? copyright.name : copyright.url #TODO
    end

    def identifier
      return '' unless @object_doc.identifier

      @object_doc.identifier.join('|')
    end

    def relation
      return nil unless @object.respond_to?(:relation)
      return nil if @object.relation.blank?
      @object.relation.join('|')
    end

    def url
      url_for(
        controller: 'catalog',
        action: 'show',
        id: @object_doc.id,
        host: @base_url
      )
    end
  end
end
