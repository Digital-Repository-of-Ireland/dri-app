# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Edm do
  # A minimal stand-in for a Solr-backed DRI record: supports hash-style
  # field access (record['some_tesim']) via the wrapped Hash, plus the
  # handful of model methods the formatter calls directly.
  class FakeEdmRecord < SimpleDelegator
    attr_accessor :id, :doi, :licence, :copyright, :collection_id,
                  :root_collection_id, :depositing_institute

    def initialize(fields = {})
      super(fields)
      @assets_list = []
      @public_read = true
      @published = true
    end

    def assets(*, **)
      @assets_list
    end

    attr_writer :assets_list

    def public_read?
      @public_read
    end
    attr_writer :public_read

    def published?
      @published
    end
    attr_writer :published
  end

  class FakeEdmAsset < SimpleDelegator
    attr_accessor :id

    def initialize(fields, id)
      super(fields)
      @id = id
    end
  end

  let(:edm_settings) do
    double(
      "edm_settings",
      _3d: "3D_OBJECT",
      video: ["MOVING IMAGE"],
      sound: ["SOUND RECORDING"],
      text: "TEXT",
      image: ["STILL IMAGE"]
    )
  end

  let(:licence) { double("licence", name: "CC-BY", url: "https://licence.example/cc-by") }
  let(:copyright) { double("copyright", url: "https://copyright.example/holder") }
  let(:institute) { double("institute", name: "Example Institute") }

  let(:image_asset) do
    FakeEdmAsset.new(
      { "file_type_tesim" => ["image"], "mime_type_tesim" => ["image/jpeg"] },
      "file1"
    )
  end

  let(:record) do
    FakeEdmRecord.new("type_tesim" => ["still image"]).tap do |r|
      r.id = "abc123"
      r.doi = nil
      r.licence = licence
      r.copyright = copyright
      r.collection_id = "col1"
      r.root_collection_id = "root1"
      r.depositing_institute = institute
      r.assets_list = [image_asset]
    end
  end

  let(:riiif) do
    double("riiif").tap do |r|
      allow(r).to receive(:image_url) { |identifier, size:| "https://example.org/iiif/#{identifier}?size=#{size}" }
      allow(r).to receive(:base_url) { |identifier| "https://example.org/iiif/base/#{identifier}" }
    end
  end

  let(:controller) do
    double("controller").tap do |c|
      allow(c).to receive(:riiif).and_return(riiif)
      allow(c).to receive(:catalog_url) { |id| "https://repository.dri.ie/catalog/#{id}" }
      allow(c).to receive(:iiif_manifest_url) { |id, **| "https://repository.dri.ie/iiif/#{id}/manifest.json" }
      allow(c).to receive(:object_file_url) { |id, file_id, surrogate:| "https://repository.dri.ie/objects/#{id}/#{file_id}?surrogate=#{surrogate}" }
      allow(c).to receive(:cover_image_url) { |cid| "https://repository.dri.ie/covers/#{cid}" }
      allow(c).to receive(:api_oembed_url).and_return("https://repository.dri.ie/oembed")
    end
  end

  let(:model) { double("model", controller: controller) }

  before do
    allow(Settings).to receive(:edm).and_return(edm_settings)
    allow(Aggregation).to receive_message_chain(:where, :first).and_return(nil)
    allow(TpStory).to receive_message_chain(:where, :first).and_return(nil)
  end

  subject(:formatter) { described_class.instance }

  describe "#valid?" do
    it "is false when the record is not published" do
      record.published = false
      expect(formatter.valid?(record)).to be false
    end

    it "is false when the record has no assets" do
      record.assets_list = []
      expect(formatter.valid?(record)).to be false
    end

    it "is false when the record is not public" do
      record.public_read = false
      expect(formatter.valid?(record)).to be false
    end

    it "is true for a published, asset-bearing, public record" do
      expect(formatter.valid?(record)).to be true
    end
  end

  describe "#encode" do
    it "returns an empty string when the record has no assets" do
      record.assets_list = []

      expect(formatter.encode(model, record)).to eq("")
    end

    it "returns an empty string when the record is not public" do
      record.public_read = false

      expect(formatter.encode(model, record)).to eq("")
    end

    it "returns an empty string when there is no asset matching the detected edm type" do
      record["type_tesim"] = ["unrecognised type"]

      expect(formatter.encode(model, record)).to eq("")
    end

    it "returns an empty string for a licence Europeana should not receive" do
      allow(licence).to receive(:name).and_return("ODC-BY")

      expect(formatter.encode(model, record)).to eq("")
    end

    it "returns an empty string when the record has no copyright" do
      record.copyright = nil

      expect(formatter.encode(model, record)).to eq("")
    end

    context "with a valid public-domain image record" do
      let(:xml) { formatter.encode(model, record) }

      it "renders the rdf:RDF root with the expected namespaces" do
        expect(xml).to include("<rdf:RDF")
        expect(xml).to include('xmlns:edm="http://www.europeana.eu/schemas/edm/"')
      end

      it "renders edm:ProvidedCHO with the record id" do
        expect(xml).to include('<edm:ProvidedCHO rdf:about="#abc123">')
      end

      it "renders the detected edm:type" do
        expect(xml).to include("<edm:type>IMAGE</edm:type>")
      end

      it "renders the dc:type metadata field from type_tesim" do
        expect(xml).to include("still image")
      end

      it "renders an ore:Aggregation referencing the ProvidedCHO and licence/copyright" do
        expect(xml).to include("<ore:Aggregation")
        expect(xml).to include('rdf:resource="#abc123"')
        expect(xml).to include(licence.url)
        expect(xml).to include(copyright.url)
      end

      it "renders edm:isShownAt pointing at the catalog landing page (no doi present)" do
        expect(xml).to include("https://repository.dri.ie/catalog/abc123")
      end

      it "renders an edm:WebResource + svcs:Service pair for the main IIIF image" do
        expect(xml).to include("<svcs:Service")
        expect(xml).to include("http://iiif.io/api/image")
      end

      it "renders a thumbnail edm:WebResource" do
        expect(xml.scan("<edm:WebResource").size).to be >= 2
      end
    end
  end
end