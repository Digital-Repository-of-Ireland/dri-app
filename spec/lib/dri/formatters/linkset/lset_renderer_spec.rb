# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Linkset::LsetRenderer do
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

  subject(:render) { described_class.new(context).render }

  describe "#render" do
    context "with only the mandatory fields" do
      let(:context) { fake_context }

      it "always includes the AboutPage type line and the describedby line" do
        expect(render).to include('<https://schema.org/AboutPage> ; rel="type" ; anchor="https://repository.dri.ie/catalog/doc1"')
        expect(render).to include(
          '<https://repository.dri.ie/objects/doc1/metadata> ; rel="describedby" ; type="application/xml" ; anchor="https://repository.dri.ie/catalog/doc1"'
        )
      end

      it "has exactly two lines when nothing optional is present" do
        expect(render.size).to eq(2)
      end
    end

    context "with a doi" do
      let(:context) { fake_context(doi: "10.1234/abc") }

      it "renders a cite-as line before anything else" do
        expect(render.first).to eq(
          '<https://doi.org/10.1234/abc> ; rel="cite-as" ; anchor="https://repository.dri.ie/catalog/doc1"'
        )
      end
    end

    context "with a schema link" do
      let(:context) { fake_context(schema_link: "https://schema.org/ImageObject") }

      it "renders a rel=type line for the schema link, ahead of the AboutPage type line" do
        expect(render[0]).to eq(
          '<https://schema.org/ImageObject> ; rel="type" ; anchor="https://repository.dri.ie/catalog/doc1"'
        )
        expect(render[1]).to include("AboutPage")
      end
    end

    context "with orcid links" do
      let(:context) { fake_context(orcid_links: ["https://orcid.org/0000-0001-1111-1111"]) }

      it "renders a rel=author line per orcid" do
        expect(render).to include(
          '<https://orcid.org/0000-0001-1111-1111> ; rel="author" ; anchor="https://repository.dri.ie/catalog/doc1"'
        )
      end
    end

    context "with link descendants" do
      let(:context) do
        fake_context(link_descendants: [{ href: "https://repository.dri.ie/downloads/doc1/f1", type: "application/pdf" }])
      end

      it "renders a rel=item line with the descendant's type" do
        expect(render).to include(
          '<https://repository.dri.ie/downloads/doc1/f1> ; rel="item" ; type="application/pdf" ; anchor="https://repository.dri.ie/catalog/doc1"'
        )
      end
    end

    context "with a license and copyright" do
      let(:context) do
        fake_context(license_link: "https://licence.example/cc-by", copyright_link: "https://copyright.example/holder")
      end

      it "renders rel=license and rel=copyright lines" do
        expect(render).to include(
          '<https://licence.example/cc-by> ; rel="license" ; anchor="https://repository.dri.ie/catalog/doc1"'
        )
        expect(render).to include(
          '<https://copyright.example/holder> ; rel="copyright" ; anchor="https://repository.dri.ie/catalog/doc1"'
        )
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

      it "renders a rel=collection line anchored on the descendant, not the document anchor_url" do
        expect(render).to include(
          '<https://repository.dri.ie/catalog/parent1> ; rel="collection" ; type="text/html" ; anchor="https://repository.dri.ie/downloads/doc1/f1"'
        )
      end
    end
  end
end
