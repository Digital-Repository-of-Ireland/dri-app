require 'csv'

module DRI::Formatters
  class Csv

    METADATA_FIELDS_MAP = {
     'title' => 'Title',
     'subject' => 'Subject',
     'creation_date' => 'Creation Date',
     'published_date' => 'Issued Date',
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
     'isGovernedBy' => 'Collection',
     'role_dnr' => 'Donor',
     'geographical_coverage' => 'Subject (Place)',
     'temporal_coverage' => 'Subject (Temporal)',
     'institute' => 'Organisation',
     'identifier' => 'Identifier'
    }

    def initialize(object_doc, options = {})
      fields = options[:fields].presence
      @with_assets = options[:with_assets].presence
      @request_fields = fields || METADATA_FIELDS_MAP.keys
      @object_doc = object_doc
    end

    def format
      titles = ['Id']
      @request_fields.each { |k| titles << METADATA_FIELDS_MAP[k] }
      titles << 'Licence'
      titles << 'Assets' if @with_assets.present?
      titles << 'Url'
      
      csv_string = CSV.generate do |csv|
        csv << titles

        row = []
        row << @object_doc['id']
        @request_fields.each do |key|
          if key == 'identifier'
            field = @object_doc.identifier
          else
            field = @object_doc[ActiveFedora.index_field_mapper.solr_name(key, :stored_searchable, type: :string)]
          end
          value = field.kind_of?(Array) ? field.join('|') : field 
          row << value || ''
        end
        row << licence
        row << assets if @with_assets.present?
        row << url

        csv << row
      end

      csv_string
    end

    def assets
      assets = @object_doc.assets
      asset_column = []
      assets.each { |a| asset_column << file_url(a['id']) }
      asset_column.join('|')
    end

    def file_url(file_id)
      Rails.application.routes.url_helpers.file_download_url(
        id: file_id,
        object_id: @object_doc['id'],
        type: 'surrogate',
        protocol: Rails.application.config.action_mailer.default_url_options[:protocol]
      )
    end

    def licence
      licence = @object_doc.licence
      return '' if licence.nil?

      (licence.name == 'All Rights Reserved') ? licence.name : licence.url
    end

    def identifier
      return '' unless @object_doc.identifier

      @object_doc.identifier.join('|')
    end

    def url
      Rails.application.routes.url_helpers.url_for(
        controller: 'catalog',
        action: 'show',
        id: @object_doc.id,
        protocol: Rails.application.config.action_mailer.default_url_options[:protocol]
      )
    end
  end
end