# frozen_string_literal: true

require "rails_helper"

RSpec.describe CollectionPermissions do
  let(:collection) { { "id" => "col123" } }

  describe ".count_with_inherited_permissions" do
    it "queries for non-collection objects with no explicit read groups and no master_file_access override, returning the count" do
      query_double = double("query", count: 3)
      expect(Solr::Query).to receive(:new).with(
        "collection_id_sim:col123",
        100,
        fq: [
          "is_collection_ssi:false",
          "-read_access_group_ssim:[* TO *]",
          "-(-master_file_access_ssi:inherit master_file_access_ssi:*)"
        ]
      ).and_return(query_double)

      expect(described_class.count_with_inherited_permissions(collection)).to eq(3)
    end
  end

  describe ".with_inherited_permissions" do
    it "returns the same query's results as an array" do
      results = [double("doc1"), double("doc2")]
      query_double = double("query", to_a: results)
      allow(Solr::Query).to receive(:new).and_return(query_double)

      expect(described_class.with_inherited_permissions(collection)).to eq(results)
    end
  end

  describe ".with_custom_permissions" do
    it "queries for objects with explicit read groups or an overridden master_file_access" do
      results = [double("doc1")]
      query_double = double("query", to_a: results)
      expect(Solr::Query).to receive(:new).with(
        "collection_id_sim:col123",
        100,
        fq: [
          "is_collection_ssi:false",
          "read_access_group_ssim:[* TO *] OR (-master_file_access_ssi:inherit master_file_access_ssi:[* TO *])"
        ]
      ).and_return(query_double)

      expect(described_class.with_custom_permissions(collection)).to eq(results)
    end
  end
end
