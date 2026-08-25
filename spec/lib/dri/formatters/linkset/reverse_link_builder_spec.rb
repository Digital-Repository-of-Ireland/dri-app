# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Linkset::ReverseLinkBuilder do
  let(:controller) do
    double("controller").tap do |c|
      allow(c).to receive(:catalog_url) { |id| "https://repository.dri.ie/catalog/#{id}" }
    end
  end

  subject(:builder) { described_class.new(controller) }

  describe "#build" do
    let(:link_descendants) do
      [
        { href: "https://repository.dri.ie/downloads/doc1/file-1", type: "application/pdf" },
        { href: "https://repository.dri.ie/downloads/doc1/file-2", type: "image/jpeg" }
      ]
    end

    it "anchors each reverse link on the descendant's own href" do
      result = builder.build(link_descendants, nil, "doc1")

      expect(result.map { |r| r[:anchor] }).to eq(
        ["https://repository.dri.ie/downloads/doc1/file-1", "https://repository.dri.ie/downloads/doc1/file-2"]
      )
    end

    it "points the collection link at the document itself when there is no ancestor_id" do
      result = builder.build(link_descendants, nil, "doc1")

      expect(result.first[:collection]).to eq([{ href: "https://repository.dri.ie/catalog/doc1", type: "text/html" }])
    end

    it "points the collection link at the last ancestor id when one is present" do
      result = builder.build(link_descendants, ["root1", "parent1"], "doc1")

      expect(result.first[:collection]).to eq([{ href: "https://repository.dri.ie/catalog/parent1", type: "text/html" }])
    end

    it "returns an empty array when there are no descendants" do
      expect(builder.build([], nil, "doc1")).to eq([])
      expect(builder.build(nil, nil, "doc1")).to eq([])
    end

    it "returns one reverse-link entry per descendant" do
      result = builder.build(link_descendants, nil, "doc1")

      expect(result.size).to eq(2)
    end
  end
end
