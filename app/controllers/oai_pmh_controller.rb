class OaiPmhController < CatalogController
  include BlacklightOaiProvider::Controller
 
  protected

  def oai_catalog_url(*args)
    oai_pmh_oai_url(*args)
  end
  helper_method :oai_catalog_url
end
