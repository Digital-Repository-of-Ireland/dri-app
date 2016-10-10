# Tell RIIIF to get files via HTTP (not from the local disk)
Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new

Riiif::Image.authorization_service = RiiifAuthorizationService

# This tells RIIIF how to resolve the identifier to an asset URI
Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  ids = id.split(':')
  object_id = ids[0]
  generic_file_id = ids[1]

  surrogate =  'full'

  storage = StorageService.new
  url = storage.surrogate_url(object_id, 
           "#{generic_file_id}_#{surrogate}")
  
  url 
end

# In order to return the info.json endpoint, we have to have the full height and width of
# each image. If you are using hydra-file_characterization, you have the height & width 
# cached in Solr. The following block directs the info_service to return those values:
HEIGHT_SOLR_FIELD = 'height_isi'
WIDTH_SOLR_FIELD = 'width_isi'

Riiif::Image.info_service = lambda do |id, file|
  ids = id.split(':')
  id = ids[1]

  resp = ActiveFedora::SolrService.query("id:#{id}", defType: 'edismax', rows: '1')
  file_doc = resp.first
  resp = ActiveFedora::SolrService.query("id:#{file_doc['isPartOf_ssim'].first}", 
    defType: 'edismax', rows: '1')
  object_doc = resp.first

  { height: file_doc[HEIGHT_SOLR_FIELD], width: file_doc[WIDTH_SOLR_FIELD] }
end

Riiif::ImagesController.class_eval do

  def not_found_image
    image = Rails.root.to_s << '/public/' << ActionController::Base.helpers.image_path('dri/dri_ident.png').to_s
    model.new(image_id, Riiif::File.new(image))
  end

end

def blacklight_config
  CatalogController.blacklight_config
end

### ActiveSupport::Benchmarkable (used in Blacklight::SolrHelper) depends on a logger method

def logger
  Rails.logger
end

Riiif::Engine.config.cache_duration_in_days = 30
