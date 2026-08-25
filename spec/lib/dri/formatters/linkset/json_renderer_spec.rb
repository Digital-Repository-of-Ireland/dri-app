# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Linkset::JsonRenderer do
  def fake_context(overrides = {})
    defaults = {
      anchor_url: "https://repository.dri.ie/catalog/doc1",
      doi: nil,
      schema_link: nil,
      orcid_links: [],
      link_descendants: [],
      describedby: { href: "https://repository.dri.ie/objects/doc1/metadata", type: "application/xml" },
      license_link: nil,
      copyright_link: nil,
      reverse_link: []
    }

    double("context", defaults.merge(overrides))
  end

  subject(:parsed) { JSON.parse(described_class.new(context).render) }

  describe "#render" do
    context "with only the mandatory fields" do
      let(:context) { fake_context }

      it "sets the top-level anchor" do
        expect(parsed["linkset"][0]["anchor"]).to eq("https://repository.dri.ie/catalog/doc1")
      end

      it "always includes the AboutPage type entry" do
        expect(parsed["linkset"][0]["type"]).to eq([{ "href" => "https://schema.org/AboutPage" }])
      end

      it "always includes the describedby entry" do
        expect(parsed["linkset"][0]["describedby"]).to eq(
          [{ "href" => "https://repository.dri.ie/objects/doc1/metadata", "type" => "application/xml" }]
        )
      end

      it "omits cite-as, author, item, license and copyright when absent" do
        linkset = parsed["linkset"][0]
        expect(linkset).not_to have_key("cite-as")
        expect(linkset).not_to have_key("author")
        expect(linkset).not_to have_key("item")
        expect(linkset).not_to have_key("license")
        expect(linkset).not_to have_key("copyright")
      end

      it "includes the (possibly empty) reverse link as the second linkset array element" do
        expect(parsed["linkset"][1]).to eq([])
      end
    end

    context "with a doi" do
      let(:context) { fake_context(doi: "10.1234/abc") }

      it "includes a cite-as entry" do
        expect(parsed["linkset"][0]["cite-as"]).to eq([{ "href" => "https://doi.org/10.1234/abc" }])
      end
    end

    context "with a schema link" do
      let(:context) { fake_context(schema_link: "https://schema.org/ImageObject") }

      it "includes both the schema link and the AboutPage link, schema link first" do
        expect(parsed["linkset"][0]["type"]).to eq(
          [{ "href" => "https://schema.org/ImageObject" }, { "href" => "https://schema.org/AboutPage" }]
        )
      end
    end

    context "with orcid links" do
      let(:context) { fake_context(orcid_links: ["https://orcid.org/0000-0001-1111-1111"]) }

      it "includes an author entry per orcid" do
        expect(parsed["linkset"][0]["author"]).to eq([{ "href" => "https://orcid.org/0000-0001-1111-1111" }])
      end
    end

    context "with link descendants" do
      let(:context) do
        fake_context(link_descendants: [{ href: "https://repository.dri.ie/downloads/doc1/f1", type: "application/pdf" }])
      end

      it "includes the descendants as the item entry" do
        expect(parsed["linkset"][0]["item"]).to eq(
          [{ "href" => "https://repository.dri.ie/downloads/doc1/f1", "type" => "application/pdf" }]
        )
      end
    end

    context "with a license and copyright" do
      let(:context) do
        fake_context(license_link: "https://licence.example/cc-by", copyright_link: "https://copyright.example/holder")
      end

      it "includes license and copyright entries" do
        expect(parsed["linkset"][0]["license"]).to eq([{ "href" => "https://licence.example/cc-by" }])
        expect(parsed["linkset"][0]["copyright"]).to eq([{ "href" => "https://copyright.example/holder" }])
      end
    end

    context "with reverse links" do
      let(:context) do
        fake_context(
          reverse_link: [
            { anchor: "https://repository.dri.ie/downloads/doc1/f1", collection: [{ href: "https://repository.dri.ie/catalog/parent1", type: "text/html" }] }
          ]
        )
      end

      it "includes the reverse link structure as the second linkset array element" do
        expect(parsed["linkset"][1]).to eq(
          [
            {
              "anchor" => "https://repository.dri.ie/downloads/doc1/f1",
              "collection" => [{ "href" => "https://repository.dri.ie/catalog/parent1", "type" => "text/html" }]
            }
          ]
        )
      end
    end
  end
end
