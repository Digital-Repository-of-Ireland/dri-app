module DRI::Formatters
  class Json

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
      request_fields = options[:fields].presence || METADATA_FIELDS_MAP.keys
      @with_assets = options[:with_assets].presence
      @object_doc = object_doc
      @object_hash = object_doc.extract_metadata(request_fields)
    end

    # @param options [Hash]
    # @param func [Symbol]     default :to_json, allows for :as_json as needed
    # @return [String(json) | Hash] (Could be any type depending on :func)
    #     String | Hash are the expected outputs
    def format(options = {}, func: :to_json)
      metadata_hash = @object_hash['metadata']
      translated_hash = metadata_hash.map do |k, v|
        case k
        when 'institute'
          value = v.blank? ? v : v.map(&:name)
          [METADATA_FIELDS_MAP[k], value]
        else
          [METADATA_FIELDS_MAP[k], v]
        end
      end.to_h
      @formatted_hash = { 'Id' => @object_hash['pid'] }
      @formatted_hash.merge!(translated_hash)

      identifier = @object_doc.identifier
      @formatted_hash['Identifier'] = identifier if identifier
      @formatted_hash['Licence'] = self.class::licence(@object_doc)
      @formatted_hash['Doi'] = self.class::dois(@object_doc)
      @formatted_hash['RelatedObjects'] = @object_doc.object_relationships_as_json
      @formatted_hash['Assets'] = assets if @with_assets
      @formatted_hash.send(func)
    end

    # @param [SolrDocument] solr_doc
    # @return [Hash] licence || nil
    def self.licence(solr_doc)
      solr_doc.licence.show if !solr_doc.collection? && solr_doc.licence
    end

    # @param [SolrDocument] solr_doc
    # @return [Array] array of hashes for each doi || nil
    def self.dois(solr_doc)
      dois = DataciteDoi.where(object_id: solr_doc.id)
      return dois.map(&:show) if dois.count > 0
    end

    def assets
      assets = @object_doc.assets
      assets_json = []
      assets.each do |a|
        assets_json << { 'id' => a['id'], 'title' => a['label_tesim'], 'path' => file_url(a['id']) }
      end
      assets_json
    end

    def file_path(file_id)
      Rails.application.routes.url_helpers.file_download_path(id: file_id, object_id: @object_doc['id'], type: 'surrogate')
    end

    def file_url(file_id)
      Rails.application.routes.url_helpers.file_download_url(id: file_id, object_id: @object_doc['id'], type: 'surrogate')
    end
  end
end
