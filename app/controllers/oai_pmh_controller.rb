class OaiPmhController < CatalogController
  include BlacklightOaiProvider::Controller
 
  BlacklightOaiProvider::SolrDocumentProvider.register_format(DRI::Formatters::EDM.instance)
  BlacklightOaiProvider::SolrDocumentProvider.register_format(DRI::Formatters::OAI.instance)

  protected

  def oai_catalog_url(*args)
    oai_pmh_oai_url(*args)
  end
  helper_method :oai_catalog_url
end
