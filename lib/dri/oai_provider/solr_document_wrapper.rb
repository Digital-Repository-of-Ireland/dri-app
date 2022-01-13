# frozen_string_literal: true
module DRI::OaiProvider
  class SolrDocumentWrapper < ::BlacklightOaiProvider::SolrDocumentWrapper
    attr_reader :controller
  end
end
