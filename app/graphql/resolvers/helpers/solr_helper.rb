module Resolvers::Helpers::SolrHelper
  # TODO: should never use .where with tesim fields because they're tokenized
  # which fields have sim equivalent? replace tesim for search
  # add test that checks every field, try one character queries e.g.  
  # DRI::QualifiedDublinCore.where('subject_tesim': '*t*').count
  def collection_field
    # ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)
    Solr::SchemaFields.facet('is_collection')
  end

  def generic_file_field
    # ActiveFedora.index_field_mapper.solr_name('has_model')
    Solr::SchemaFields.searchable_symbol('has_model')
  end

  # @param [String] field
  # @param [String] value
  # @return [String]
  def contains_query(field, value)
    "#{ActiveFedora.index_field_mapper.solr_name(field)}:*#{value}*"
    # contains_query_hash(field, value).first.join('')
  end

  # @param [String] field
  # @param [String] value
  # @return [String]
  def is_query(field, value)
    "#{ActiveFedora.index_field_mapper.solr_name(field)}:#{value}"
    # is_query_hash(field, value).first.join('')
  end

  # @param [String] field
  # @param [String] value
  # @return [Hash]
  def contains_query_hash(field, value)
    { "#{ActiveFedora.index_field_mapper.solr_name(field)}": "*#{value}*" }
  end

  # @param [String] field
  # @param [String] value
  # @return [Hash]
  def is_query_hash(field, value)
    { "#{ActiveFedora.index_field_mapper.solr_name(field)}": "#{value}" }
  end

  # @param [Hash] value
  # @return [Hash]
  def query_hash(value)
    query_args = {}
    value.each do |k, v|
      k = k.to_s
      # split on last occurrence of _
      field, _, query_type = k.rpartition('_')
      # assumes no key collisions (i.e. more than one request for a given field)
      # filter(licence: 'test' or licence: 'real') would need to be parsed in advance
      # to generate licence_sim:('test' OR 'real')
      query_args.merge!(send("#{query_type}_query_hash", field, v))
    end
    query_args
  end

  # @param [Hash] value
  # @return [Array] array of strings
  def query_array(value)    
    value.map do |k, v|
      k = k.to_s
      # split on last occurrence of _
      field, _, query_type = k.rpartition('_')
      send("#{query_type}_query", field, v)
    end
  end
end
