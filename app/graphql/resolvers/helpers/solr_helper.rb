module Resolvers::Helpers::SolrHelper
  def collection_field
    ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)
  end

  def generic_file_field
    # Solr::SchemaFields.searchable_symbol('has_model')}:\"DRI::GenericFile\"
    ActiveFedora.index_field_mapper.solr_name('has_model')
  end
end
