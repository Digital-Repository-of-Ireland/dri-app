# frozen_string_literal: true
    
# Solr lookups for objects within a collection that have custom
# (non-inherited) access permissions, vs. objects that inherit them
# from their governing collection.
class CollectionPermissions
  def self.count_with_inherited_permissions(collection)
    new(collection).count_with_inherited_permissions
  end

  def self.with_inherited_permissions(collection)
    new(collection).with_inherited_permissions
  end

  def self.with_custom_permissions(collection)
    new(collection).with_custom_permissions
  end

  def initialize(collection)
    @collection = collection
  end

  def count_with_inherited_permissions
    inherited_query.count
  end

  def with_inherited_permissions
    inherited_query.to_a
  end

  def with_custom_permissions
    custom_query.to_a
  end

  private

  attr_reader :collection

  def inherited_query
    Solr::Query.new(
      "collection_id_sim:#{collection['id']}",
      100,
      fq: [
        'is_collection_ssi:false',
        '-read_access_group_ssim:[* TO *]',
        '-(-master_file_access_ssi:inherit master_file_access_ssi:*)'
      ]
    )
  end

  def custom_query
    Solr::Query.new(
      "collection_id_sim:#{collection['id']}",
      100,
      fq: [
        'is_collection_ssi:false',
        'read_access_group_ssim:[* TO *] OR (-master_file_access_ssi:inherit master_file_access_ssi:[* TO *])'
      ]
    )
  end
end