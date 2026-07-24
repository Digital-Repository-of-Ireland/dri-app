# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Edm::FieldMapper do
  describe ".language_diff" do
    it "subtracts the language-tagged values from the base field" do
      record = {
        "title_tesim" => ["Irish Famine", "Gorta Mor", "Some English Title"],
        "title_eng_tesim" => ["Some English Title"],
        "title_gle_tesim" => ["Gorta Mor"]
      }

      result = described_class.language_diff(record, "title_tesim", "title_eng_tesim", "title_gle_tesim")

      expect(result).to eq(["Irish Famine"])
    end

    it "strips whitespace before comparing" do
      record = {
        "title_tesim" => [" Same Title "],
        "title_eng_tesim" => ["Same Title"]
      }

      result = described_class.language_diff(record, "title_tesim", "title_eng_tesim")

      expect(result).to eq([])
    end

    it "returns the base values unchanged when there is nothing to subtract" do
      record = { "title_tesim" => ["A Title"] }

      result = described_class.language_diff(record, "title_tesim", "title_eng_tesim", "title_gle_tesim")

      expect(result).to eq(["A Title"])
    end

    it "handles a missing base field gracefully" do
      result = described_class.language_diff({}, "title_tesim", "title_eng_tesim")

      expect(result).to eq([])
    end
  end

  describe ".values_for" do
    it "resolves a single Solr field name into a flat array" do
      record = { "creator_tesim" => ["A. Author"] }

      expect(described_class.values_for("creator_tesim", record)).to eq(["A. Author"])
    end

    it "resolves an array of field names, flattening and compacting the result" do
      record = { "a" => ["one"], "b" => nil, "c" => ["two", "three"] }

      expect(described_class.values_for(%w[a b c], record)).to eq(["one", "two", "three"])
    end

    it "returns an empty array when the field is missing" do
      expect(described_class.values_for("missing_field", {})).to eq([])
    end

    it "calls a Proc source with the record and returns its result directly" do
      record = { "subject_tesim" => ["x"] }
      source = ->(rec) { rec["subject_tesim"].map(&:upcase) }

      expect(described_class.values_for(source, record)).to eq(["X"])
    end
  end

  describe ".each_field" do
    it "returns an Enumerator when called without a block" do
      expect(described_class.each_field).to be_a(Enumerator)
    end

    it "yields every configured field across all prefixes" do
      expected_count = described_class::PREFIXES.values.sum(&:size)

      count = 0
      described_class.each_field { |_prefix, _key, _source| count += 1 }

      expect(count).to eq(expected_count)
    end

    it "yields the edm:type field backed by object_type_ssm" do
      matched = described_class.each_field.to_a.find { |prefix, key, _source| prefix == :edm && key == :type }

      expect(matched.last).to eq("object_type_ssm")
    end

    it "yields dc:title as a Proc (computed field), not a plain Solr field name" do
      matched = described_class.each_field.to_a.find { |prefix, key, _source| prefix == :dc && key == :title }

      expect(matched.last).to be_a(Proc)
    end
  end
end
