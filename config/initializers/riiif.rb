# Tell RIIIF to get files via HTTP (not from the local disk)
Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new

# This tells RIIIF how to resolve the identifier to a URI in Fedora
Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  generic_file = DRI::GenericFile.find(id)
  object = generic_file.batch
  surrogate =  'optimized_web_format'

  storage = StorageService.new
  url = storage.surrogate_url(object.id, 
           "#{generic_file.id}_#{surrogate}")

  url 
end

# In order to return the info.json endpoint, we have to have the full height and width of
# each image. If you are using hydra-file_characterization, you have the height & width 
# cached in Solr. The following block directs the info_service to return those values:
HEIGHT_SOLR_FIELD = 'height_isi'
WIDTH_SOLR_FIELD = 'width_isi'
Riiif::Image.info_service = lambda do |id, file|
  resp = get_solr_response_for_doc_id id
  doc = resp.first['response']['docs'].first
  { height: doc[HEIGHT_SOLR_FIELD], width: doc[WIDTH_SOLR_FIELD] }
end

def blacklight_config
  CatalogController.blacklight_config
end

### ActiveSupport::Benchmarkable (used in Blacklight::SolrHelper) depends on a logger method

def logger
  Rails.logger
end

Riiif::Engine.config.cache_duration_in_days = 30
