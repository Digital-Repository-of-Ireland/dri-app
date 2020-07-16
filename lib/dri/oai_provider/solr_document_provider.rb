module DRI::OaiProvider
  class SolrDocumentProvider < ::BlacklightOaiProvider::SolrDocumentProvider

    def initialize(controller, options = {})
      options[:provider] ||= {}
      options[:document] ||= {}

      self.class.model = ::DRI::OaiProvider::SolrDocumentWrapper.new(controller, options[:document])

      options[:repository_name] ||= controller.view_context.send(:application_name)
      options[:repository_url] ||= controller.view_context.send(:oai_catalog_url)

      options[:provider].each do |k, v|
        self.class.send k, v
      end
    end
  end
end
