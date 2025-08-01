class OaiPmhController < ApplicationController
  include DRI::Catalog
  include BlacklightOaiProvider::Controller
  copy_blacklight_config_from(CatalogController)

  DRI::OaiProvider::SolrDocumentProvider.register_format(DRI::Formatters::Edm.instance)
  DRI::OaiProvider::SolrDocumentProvider.register_format(DRI::Formatters::OpenAire.instance)
  DRI::OaiProvider::SolrDocumentProvider.register_format(DRI::Formatters::Oai.instance)

  def oai
    body = oai_provider
           .process_request(oai_params.to_h)
           .gsub('<?xml version="1.0" encoding="UTF-8"?>') do |m|
             "#{m}\n<?xml-stylesheet type=\"text/xsl\" href=\"#{ActionController::Base.helpers.asset_path('blacklight_oai_provider/oai_dri.xsl')}\"?>\n"
           end
    render xml: body, content_type: 'text/xml'
  end

  def oai_provider
    @oai_provider ||= DRI::OaiProvider::SolrDocumentProvider.new(self, oai_config)
  end

  protected

  def oai_catalog_url(*args)
    oai_pmh_oai_url(*args)
  end
  helper_method :oai_catalog_url
end
