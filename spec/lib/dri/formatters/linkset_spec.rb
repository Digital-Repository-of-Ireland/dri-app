# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Linkset do
  let(:controller) { double("controller") }
  let(:document) { double("document") }

  subject(:formatter) { described_class.new(controller, document) }

  describe "#format" do
    it "defaults to the lset (line) format when no format option is given" do
      expect(formatter).to receive(:lset).and_return(["line 1"])

      expect(formatter.format).to eq(["line 1"])
    end

    it "renders lset when format: :lset is given explicitly" do
      expect(formatter).to receive(:lset).and_return(["line 1"])

      expect(formatter.format(format: :lset)).to eq(["line 1"])
    end

    it "renders json for any other format value" do
      expect(formatter).to receive(:json).and_return("{}")

      expect(formatter.format(format: :json)).to eq("{}")
    end
  end

  describe "#lset" do
    it "builds a Context and renders it with LsetRenderer" do
      context = instance_double(DRI::Formatters::Linkset::Context)
      allow(DRI::Formatters::Linkset::Context).to receive(:new).with(controller, document).and_return(context)
      expect(DRI::Formatters::Linkset::LsetRenderer).to receive(:new).with(context).and_call_original
      allow_any_instance_of(DRI::Formatters::Linkset::LsetRenderer).to receive(:render).and_return(["a line"])

      expect(formatter.lset).to eq(["a line"])
    end
  end

  describe "#json" do
    it "builds a Context and renders it with JsonRenderer" do
      context = instance_double(DRI::Formatters::Linkset::Context)
      allow(DRI::Formatters::Linkset::Context).to receive(:new).with(controller, document).and_return(context)
      expect(DRI::Formatters::Linkset::JsonRenderer).to receive(:new).with(context).and_call_original
      allow_any_instance_of(DRI::Formatters::Linkset::JsonRenderer).to receive(:render).and_return("{}")

      expect(formatter.json).to eq("{}")
    end
  end

  describe "backward-compatible wrapper methods" do
    it "#mapped_links delegates to SchemaTypeMapper.lookup" do
      expect(DRI::Formatters::Linkset::SchemaTypeMapper).to receive(:lookup).with(["image"], DRI::Formatters::Linkset::SchemaTypeMapper::SCHEMA_TYPES).and_return("https://schema.org/ImageObject")

      expect(formatter.mapped_links(["image"])).to eq("https://schema.org/ImageObject")
    end

    it "#mapped_links passes through a custom map argument" do
      custom_map = { "foo" => "bar" }
      expect(DRI::Formatters::Linkset::SchemaTypeMapper).to receive(:lookup).with(["foo"], custom_map).and_return("bar")

      expect(formatter.mapped_links(["foo"], custom_map)).to eq("bar")
    end

    it "#contributors delegates to ContributorLinks.for" do
      expect(DRI::Formatters::Linkset::ContributorLinks).to receive(:for).with(document).and_return(["https://orcid.org/x"])

      expect(formatter.contributors).to eq(["https://orcid.org/x"])
    end

    it "#collection_objects delegates to CollectionLinkBuilder" do
      expect_any_instance_of(DRI::Formatters::Linkset::CollectionLinkBuilder).to receive(:build).with(document).and_return([{ href: "x" }])

      expect(formatter.collection_objects).to eq([{ href: "x" }])
    end

    it "#object_items delegates to AssetLinkBuilder" do
      assets = [double("asset")]
      expect_any_instance_of(DRI::Formatters::Linkset::AssetLinkBuilder).to receive(:build).with(assets, "doc1").and_return([{ href: "y" }])

      expect(formatter.object_items(assets, "doc1")).to eq([{ href: "y" }])
    end

    it "#document_licence_link delegates to LicenceLink.for" do
      expect(DRI::Formatters::Linkset::LicenceLink).to receive(:for).with(document).and_return("https://licence.example/cc-by")

      expect(formatter.document_licence_link).to eq("https://licence.example/cc-by")
    end

    it "#metadata_link delegates to MetadataLinkBuilder" do
      expect_any_instance_of(DRI::Formatters::Linkset::MetadataLinkBuilder).to receive(:build).with(document).and_return(href: "meta")

      expect(formatter.metadata_link).to eq(href: "meta")
    end

    it "#reverse_link_builder delegates to ReverseLinkBuilder" do
      descendants = [{ href: "x" }]
      expect_any_instance_of(DRI::Formatters::Linkset::ReverseLinkBuilder)
        .to receive(:build).with(descendants, ["ancestor1"], "doc1").and_return([{ anchor: "x" }])

      expect(formatter.reverse_link_builder(descendants, ["ancestor1"], "doc1")).to eq([{ anchor: "x" }])
    end
  end
end
