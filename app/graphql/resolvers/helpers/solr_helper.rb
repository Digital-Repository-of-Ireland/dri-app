module Resolvers::Helpers::SolrHelper
  class DriQueryError < StandardError
  end

  def collection_field
    ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)
  end

  def generic_file_field
    # Solr::SchemaFields.searchable_symbol('has_model')}:\"DRI::GenericFile\"
    ActiveFedora.index_field_mapper.solr_name('has_model')
  end

  def contains_query(field, value)
    "#{ActiveFedora.index_field_mapper.solr_name(field)}: *#{value}*"
  end

  def is_query(field, value)
    "#{ActiveFedora.index_field_mapper.solr_name(field)}: #{value}"
  end

  # def query_types
  #   %[contains is]
  # end


  # # @param [String] query
  # # @return [Boolean]
  # def valid_query?(query)
  #   return false unless query.count('_') == 1

  #   field, query_type = query.split('_')
  #   return false unless self.class.fields.key?(field)

  #   return false unless query_types.include?(query_type)

  #   return true      
  # end

  # # @param [String] query
  # def valid_query!(query)
  #   raise DriQueryError, "query #{query} missing _" unless query.count('_') == 1

  #   field, query_type = query.split('_')
  #   unless self.class.fields.key?(field) do
  #     raise DriQueryError, "#{self.class} does not accept queries for field: #{field}" 
  #   end

  #   unless query_types.include?(query_type) do
  #     raise DriQueryError, "invalid query type #{query_type}. Try #{query_types}" 
  #   end

  #   return true
  # end
end
