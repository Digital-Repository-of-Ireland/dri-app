# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Linkset::MetadataLinkBuilder do
  let(:controller) do
    double("controller").tap do |c|
      allow(c).to receive(:object_metadata_url) { |id| "https://repository.dri.ie/objects/#{id}/metadata" }
    end
  end

  subject(:builder) { described_class.new(controller) }

  describe "#build" do
    it "builds an href/type describedby link" do
      document = double("document", id: "doc1", :[] => nil)

      link = builder.build(document)

      expect(link[:href]).to eq("https://repository.dri.ie/objects/doc1/metadata")
      expect(link[:type]).to eq("application/xml")
    end

    it "does not include a :profile key when no schema profile matches" do
      document = double("document", id: "doc1", :[] => nil)

      link = builder.build(document)

      expect(link).not_to have_key(:profile)
    end

    it "includes a :profile key when the SchemaTypeMapper would resolve one" do
      document = double("document", id: "doc1", :[] => ["some-model"])
      allow(DRI::Formatters::Linkset::SchemaTypeMapper).to receive(:lookup)
        .with(["some-model"], DRI::Formatters::Linkset::SchemaTypeMapper::XML_PROFILE)
        .and_return("https://example.org/schema.xsd")

      link = builder.build(document)

      expect(link[:profile]).to eq("https://example.org/schema.xsd")
    end
  end
end
