module Resolvers::Helpers::SolrHelper
  class DriQueryError < StandardError
  end

  # TODO: should never use .where with tesim fields because they're tokenized
  # which fields have sim equivalent? replace tesim for search
  # add test that checks every field, try one character queries e.g.  
  # DRI::QualifiedDublinCore.where('subject_tesim': '*t*').count
  def collection_field
    ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)
  end

  def generic_file_field
    # Solr::SchemaFields.searchable_symbol('has_model')}:\"DRI::GenericFile\"
    ActiveFedora.index_field_mapper.solr_name('has_model')
  end

  def contains_query(field, value)
    "#{ActiveFedora.index_field_mapper.solr_name(field)}:*#{value}*"
  end

  def is_query(field, value)
    "#{ActiveFedora.index_field_mapper.solr_name(field)}:#{value}"
  end

  def contains_query_hash(field, value)
    { "#{ActiveFedora.index_field_mapper.solr_name(field)}": "*#{value}*" }
  end

  def is_query_hash(field, value)
    { "#{ActiveFedora.index_field_mapper.solr_name(field)}": "#{value}" }
  end
end
