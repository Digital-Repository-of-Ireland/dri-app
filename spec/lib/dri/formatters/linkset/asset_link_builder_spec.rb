# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Linkset::AssetLinkBuilder do
  let(:controller) do
    double("controller").tap do |c|
      allow(c).to receive(:file_download_url) do |id:, object_id:, type:|
        "https://repository.dri.ie/downloads/#{object_id}/#{id}?type=#{type}"
      end
    end
  end

  let(:document) { double("document", read_master?: false) }

  subject(:builder) { described_class.new(controller, document) }

  def asset(fields, text: false, pdf: false, threed: false)
    double("asset", :[] => nil).tap do |a|
      fields.each { |k, v| allow(a).to receive(:fetch).with(k, nil).and_return(v) }
      allow(a).to receive(:text?).and_return(text)
      allow(a).to receive(:pdf?).and_return(pdf)
      allow(a).to receive(:threeD?).and_return(threed)
    end
  end

  describe "#build" do
    it "strips brackets and quotes from the raw id/mime_type field values" do
      pdf_asset = asset({ "id" => '["file-1"]', "mime_type_tesim" => '["application/pdf"]' }, pdf: true)

      links = builder.build([pdf_asset], "doc1")

      expect(links.first[:href]).to eq("https://repository.dri.ie/downloads/doc1/file-1?type=surrogate")
    end

    it "builds a single link for a pdf asset whose mime type is already application/pdf" do
      pdf_asset = asset({ "id" => "file-1", "mime_type_tesim" => "application/pdf" }, pdf: true)

      links = builder.build([pdf_asset], "doc1")

      expect(links.size).to eq(1)
      expect(links.first[:type]).to eq("application/pdf")
    end

    it "builds a pdf surrogate link for a text asset whose mime type is not pdf" do
      text_asset = asset({ "id" => "file-1", "mime_type_tesim" => "text/plain" }, text: true)

      links = builder.build([text_asset], "doc1")

      expect(links.size).to eq(1)
      expect(links.first[:type]).to eq("application/pdf")
    end

    it "adds a second masterfile-ish link for a text asset when the document allows master access" do
      allow(document).to receive(:read_master?).and_return(true)
      text_asset = asset({ "id" => "file-1", "mime_type_tesim" => "text/plain" }, text: true)

      links = builder.build([text_asset], "doc1")

      expect(links.size).to eq(2)
      expect(links.map { |l| l[:type] }).to contain_exactly("application/pdf", "text/plain")
    end

    it "does not add a second link for a text asset when the document does not allow master access" do
      text_asset = asset({ "id" => "file-1", "mime_type_tesim" => "text/plain" }, text: true)

      links = builder.build([text_asset], "doc1")

      expect(links.size).to eq(1)
    end

    it "builds a single link for a 3d asset" do
      threed_asset = asset({ "id" => "file-1", "mime_type_tesim" => "model/gltf+json" }, threed: true)

      links = builder.build([threed_asset], "doc1")

      expect(links.size).to eq(1)
      expect(links.first[:type]).to eq("model/gltf+json")
    end

    it "builds a single link for any other asset type using its own mime type" do
      other_asset = asset({ "id" => "file-1", "mime_type_tesim" => "audio/mpeg" }, text: false, pdf: false, threed: false)

      links = builder.build([other_asset], "doc1")

      expect(links.size).to eq(1)
      expect(links.first[:type]).to eq("audio/mpeg")
    end

    it "always requests a surrogate download regardless of asset type (a quirk preserved from the original)" do
      threed_asset = asset({ "id" => "file-1", "mime_type_tesim" => "model/gltf+json" }, threed: true)

      links = builder.build([threed_asset], "doc1")

      expect(links.first[:href]).to include("type=surrogate")
    end

    it "builds links for multiple assets in order" do
      asset1 = asset({ "id" => "file-1", "mime_type_tesim" => "application/pdf" }, pdf: true)
      asset2 = asset({ "id" => "file-2", "mime_type_tesim" => "audio/mpeg" })

      links = builder.build([asset1, asset2], "doc1")

      expect(links.size).to eq(2)
      expect(links.map { |l| l[:href] }).to eq(
        [
          "https://repository.dri.ie/downloads/doc1/file-1?type=surrogate",
          "https://repository.dri.ie/downloads/doc1/file-2?type=surrogate"
        ]
      )
    end
  end
end
