# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Linkset::Context do
  let(:controller) do
    double("controller").tap do |c|
      allow(c).to receive(:catalog_url) { |id| "https://repository.dri.ie/catalog/#{id}" }
      allow(c).to receive(:object_metadata_url) { |id| "https://repository.dri.ie/objects/#{id}/metadata" }
    end
  end

  let(:document) do
    double(
      "document",
      id: "doc1",
      type: ["image"],
      copyright: double("copyright", url: "https://copyright.example/holder"),
      collection?: false,
      assets: [],
      :[] => nil
    )
  end

  before do
    allow(DRI::Formatters::Linkset::DoiLookup).to receive(:resolve).with(document).and_return("10.1234/abc")
    allow(DRI::Formatters::Linkset::ContributorLinks).to receive(:for).with(document).and_return(["https://orcid.org/0000-0001-1111-1111"])
    allow(DRI::Formatters::Linkset::LicenceLink).to receive(:for).with(document).and_return("https://licence.example/cc-by")
  end

  describe "#initialize" do
    it "resolves the anchor_url from the controller and the document id" do
      context = described_class.new(controller, document)

      expect(context.anchor_url).to eq("https://repository.dri.ie/catalog/doc1")
    end

    it "delegates doi resolution to DoiLookup" do
      context = described_class.new(controller, document)

      expect(context.doi).to eq("10.1234/abc")
    end

    it "delegates schema type resolution to SchemaTypeMapper using the document's type" do
      context = described_class.new(controller, document)

      expect(context.schema_link).to eq("https://schema.org/ImageObject")
    end

    it "delegates orcid resolution to ContributorLinks" do
      context = described_class.new(controller, document)

      expect(context.orcid_links).to eq(["https://orcid.org/0000-0001-1111-1111"])
    end

    it "delegates licence resolution to LicenceLink" do
      context = described_class.new(controller, document)

      expect(context.license_link).to eq("https://licence.example/cc-by")
    end

    it "reads the copyright url straight off the document" do
      context = described_class.new(controller, document)

      expect(context.copyright_link).to eq("https://copyright.example/holder")
    end

    it "builds link_descendants via AssetLinkBuilder for a non-collection document" do
      expect_any_instance_of(DRI::Formatters::Linkset::AssetLinkBuilder).to receive(:build).with([], "doc1").and_return([])

      context = described_class.new(controller, document)

      expect(context.link_descendants).to eq([])
    end

    it "builds link_descendants via CollectionLinkBuilder for a collection document" do
      collection_document = double(
        "document", id: "doc1", type: ["collection"],
        copyright: nil, collection?: true, :[] => nil
      )
      allow(DRI::Formatters::Linkset::DoiLookup).to receive(:resolve).and_return(nil)
      allow(DRI::Formatters::Linkset::ContributorLinks).to receive(:for).and_return(nil)
      allow(DRI::Formatters::Linkset::LicenceLink).to receive(:for).and_return(nil)
      expect_any_instance_of(DRI::Formatters::Linkset::CollectionLinkBuilder).to receive(:build).with(collection_document).and_return([{ href: "x", type: "text/html" }])

      context = described_class.new(controller, collection_document)

      expect(context.link_descendants).to eq([{ href: "x", type: "text/html" }])
    end

    it "builds describedby via MetadataLinkBuilder" do
      expect_any_instance_of(DRI::Formatters::Linkset::MetadataLinkBuilder).to receive(:build).with(document).and_return(href: "meta-url", type: "application/xml")

      context = described_class.new(controller, document)

      expect(context.describedby).to eq(href: "meta-url", type: "application/xml")
    end

    it "prefers isGovernedBy_ssim over ancestor_id_ssim when building the reverse link's ancestor" do
      allow(document).to receive(:[]).with("isGovernedBy_ssim").and_return(["governing-collection"])
      allow(document).to receive(:[]).with("ancestor_id_ssim").and_return(["escaped-collection"])

      expect_any_instance_of(DRI::Formatters::Linkset::ReverseLinkBuilder)
        .to receive(:build).with(anything, ["governing-collection"], "doc1").and_return([])

      described_class.new(controller, document)
    end

    it "falls back to ancestor_id_ssim when isGovernedBy_ssim is absent" do
      allow(document).to receive(:[]).with("isGovernedBy_ssim").and_return(nil)
      allow(document).to receive(:[]).with("ancestor_id_ssim").and_return(["escaped-collection"])

      expect_any_instance_of(DRI::Formatters::Linkset::ReverseLinkBuilder)
        .to receive(:build).with(anything, ["escaped-collection"], "doc1").and_return([])

      described_class.new(controller, document)
    end
  end
end