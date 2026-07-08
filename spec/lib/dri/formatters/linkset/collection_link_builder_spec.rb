# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Linkset::CollectionLinkBuilder do
  let(:controller) do
    double("controller").tap do |c|
      allow(c).to receive(:catalog_url) { |id| "https://repository.dri.ie/catalog/#{id}" }
    end
  end

  subject(:builder) { described_class.new(controller) }

  describe "#build" do
    it "builds a link with type text/html for a subcollection child" do
      child = double("child", id: "sub1", collection?: true)
      document = double("document")
      allow(document).to receive(:children).with(chunk: 1000, sort: nil, subcollections_only: false).and_return([child])

      links = builder.build(document)

      expect(links).to eq([{ href: "https://repository.dri.ie/catalog/sub1", type: "text/html" }])
    end

    it "builds a link with the object's own mime type for a non-collection child" do
      child = double("child", id: "obj1", collection?: false, mime_type: "image/jpeg")
      document = double("document")
      allow(document).to receive(:children).with(chunk: 1000, sort: nil, subcollections_only: false).and_return([child])

      links = builder.build(document)

      expect(links).to eq([{ href: "https://repository.dri.ie/catalog/obj1", type: "image/jpeg" }])
    end

    it "builds one link per direct child, in order" do
      child1 = double("child1", id: "obj1", collection?: false, mime_type: "image/jpeg")
      child2 = double("child2", id: "sub1", collection?: true)
      document = double("document")
      allow(document).to receive(:children).with(chunk: 1000, sort: nil, subcollections_only: false).and_return([child1, child2])

      links = builder.build(document)

      expect(links.map { |l| l[:href] }).to eq(
        ["https://repository.dri.ie/catalog/obj1", "https://repository.dri.ie/catalog/sub1"]
      )
    end

    it "returns an empty array when the collection has no children" do
      document = double("document")
      allow(document).to receive(:children).with(chunk: 1000, sort: nil, subcollections_only: false).and_return([])

      expect(builder.build(document)).to eq([])
    end
  end
end
