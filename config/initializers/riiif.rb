# Tell RIIIF to get files via HTTP (not from the local disk)
Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new

Riiif::Image.authorization_service = RiiifAuthorizationService

# This tells RIIIF how to resolve the identifier to a URI in Fedora
Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  generic_file = DRI::GenericFile.find(id)
  object = generic_file.batch

  surrogate =  'full'

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
  resp = ActiveFedora::SolrService.query("id:#{id}", defType: 'edismax', rows: '1')
  file_doc = resp.first
  resp = ActiveFedora::SolrService.query("id:#{file_doc['isPartOf_ssim'].first}", defType: 'edismax', rows: '1')
  object_doc = resp.first

  { height: file_doc[HEIGHT_SOLR_FIELD], width: file_doc[WIDTH_SOLR_FIELD] }
end

def blacklight_config
  CatalogController.blacklight_config
end

### ActiveSupport::Benchmarkable (used in Blacklight::SolrHelper) depends on a logger method

def logger
  Rails.logger
end

Riiif::Engine.config.cache_duration_in_days = 30
