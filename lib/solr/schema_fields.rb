# frozen_string_literal: true
module Solr::SchemaFields
  def self.facet(field)
    "#{field}_sim"
  end

  def self.searchable_string(field)
    "#{field}_tesim"
  end

  def self.searchable_symbol(field)
    "#{field}_ssim"
  end
end
