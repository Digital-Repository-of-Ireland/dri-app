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
     'institute' => 'Organisation'
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
      
      titles << 'License'
      titles << 'Assets' if @with_assets.present?
      
      csv_string = CSV.generate do |csv|
        csv << titles

        row = []
        row << @object_doc['id']
        @request_fields.each do |key|
          field = @object_doc[ActiveFedora.index_field_mapper.solr_name(key, :stored_searchable, type: :string)]
          value = field.kind_of?(Array) ? field.join(',') : field 
          row << value
        end
        row << licence

        if @with_assets.present?
          row << assets
        end

        csv << row
      end

      csv_string
    end

    def assets
      assets = @object_doc.assets
      asset_column = []
      assets.each do |a| 
        asset_column << file_path(a['id'])
      end
      asset_column.join(',')
    end

    def file_path(file_id)
      Rails.application.routes.url_helpers.file_download_path(id: file_id, object_id: @object_doc['id'], type: 'surrogate')
    end

    def licence
      licence = @object_doc.licence
      if licence
        value = (licence.name == 'All Rights Reserved') ? licence.name : licence.url
      end

      value
    end
  end
end