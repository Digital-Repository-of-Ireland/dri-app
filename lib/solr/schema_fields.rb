# frozen_string_literal: true
module Solr::SchemaFields
  def self.facet(field)
    Solrizer.solr_name(field, :facetable)
  end

  def self.searchable_string(field)
    stored_searchable(field, :string)
  end

  def self.searchable_symbol(field)
    stored_searchable(field, :symbol)
  end

  def self.stored_searchable(field, type)
    Solrizer.solr_name(field, :stored_searchable, type: type)
  end
end
