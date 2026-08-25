# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Linkset::SchemaTypeMapper do
  describe ".lookup" do
    it "returns the mapped schema.org url for a known type" do
      expect(described_class.lookup(["image"])).to eq("https://schema.org/ImageObject")
    end

    it "matches case-insensitively against SCHEMA_TYPES (its keys are lowercase)" do
      expect(described_class.lookup(["Image"])).to eq("https://schema.org/ImageObject")
      expect(described_class.lookup(["IMAGE"])).to eq("https://schema.org/ImageObject")
    end

    it "returns the first match when given several candidate types" do
      expect(described_class.lookup(%w[unknown-type sound])).to eq("https://schema.org/AudioObject")
    end

    it "returns nil when nothing matches" do
      expect(described_class.lookup(["not-a-real-type"])).to be_nil
    end

    it "accepts a single (non-array) type value" do
      expect(described_class.lookup("dataset")).to eq("https://schema.org/Dataset")
    end

    it "returns nil for a blank/empty list of types" do
      expect(described_class.lookup([])).to be_nil
      expect(described_class.lookup(nil)).to be_nil
    end

    context "with the XML_PROFILE map" do
      it "returns the mapped schema.org url for a known type" do
        lowercase_map = { "dri::qualifieddublincore" => "https://example.org/schema.xsd" }

        result = described_class.lookup(["DRI::QualifiedDublinCore"], lowercase_map)

        expect(result).to eq("https://example.org/schema.xsd")
      end
    end
  end
end
