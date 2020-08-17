# Tell RIIIF to get files via HTTP (not from the local disk)
Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new
Riiif::Image.authorization_service = RiiifAuthorizationService

# This tells RIIIF how to resolve the identifier to an asset URI
Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  ids = id.split(':')
  object_id = ids[0]
  image_id = ids[1]

  image_key = if object_id != image_id
                "#{image_id}_full"
              else
                "#{image_id}"
              end

  storage = StorageService.new
  url = storage.surrogate_url(object_id, image_key)

  raise Riiif::ImageNotFoundError unless url

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

  image_doc = SolrDocument.find(id)
  return { height: 128, width: 228 } if image_doc.collection?

  object_doc = SolrDocument.find("#{image_doc['isPartOf_ssim'].first}")

  { height: image_doc[HEIGHT_SOLR_FIELD], width: image_doc[WIDTH_SOLR_FIELD] }
end

def blacklight_config
  CatalogController.blacklight_config
end

### ActiveSupport::Benchmarkable (used in Blacklight::SolrHelper) depends on a logger method

def logger
  Rails.logger
end

Riiif::Engine.config.cache_duration = 30.days
