# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::OpenAire do
  # Minimal stand-in for a Solr-backed DRI record: hash-style field access
  # via the wrapped Hash, plus the handful of model methods #valid? and
  # #encode call directly.
  class FakeOpenAireRecord < SimpleDelegator
    attr_accessor :id, :licence, :copyright, :depositing_institute, :visibility

    def initialize(fields = {})
      super(fields)
      @allow_aggregation = true
      @setspec = ["openaire_data"]
      @published = true
      @assets_size = 1
      @object_type = ["text"]
      @text = true
      @image = false
      @video = false
      @audio = false
      @threed = false
      @interactive = false
    end

    def allow_aggregation?
      @allow_aggregation
    end
    attr_writer :allow_aggregation

    attr_accessor :setspec

    def published?
      @published
    end
    attr_writer :published

    def assets
      Array.new(@assets_size)
    end
    attr_writer :assets_size

    def object_type
      @object_type
    end
    attr_writer :object_type

    def text?
      @text
    end
    attr_writer :text

    def image?
      @image
    end

    def video?
      @video
    end

    def audio?
      @audio
    end

    def threeD?
      @threed
    end

    def interactive_resource?
      @interactive
    end
  end

  let(:record) do
    FakeOpenAireRecord.new(
      "creator_tesim" => ["A. Author"],
      "title_tesim" => ["A Title"],
      "description_tesim" => ["A description"],
      "rights_tesim" => ["Some rights statement"],
      "subject_tesim" => ["History"],
      "published_at_dttsi" => "2020-01-15T00:00:00Z"
    ).tap do |r|
      r.id = "abc123"
      r.depositing_institute = double("institute", name: "Example Institute")
      r.visibility = "public"
      r.licence = double("licence", url: "https://licence.example/cc-by", name: "CC-BY")
      r.copyright = nil
    end
  end

  let(:model) { double("model", controller: double("controller")) }

  before do
    allow(DataciteDoi).to receive(:find_by).with(object_id: "abc123").and_return(nil)
  end

  subject(:formatter) { described_class.instance }

  describe "#valid?" do
    it "is false when the record does not allow aggregation" do
      record.allow_aggregation = false
      expect(formatter.valid?(record)).to be false
    end

    it "is false when the record's setspec doesn't include openaire_data" do
      record.setspec = ["some_other_set"]
      expect(formatter.valid?(record)).to be false
    end

    it "is false when the record is not published" do
      record.published = false
      expect(formatter.valid?(record)).to be false
    end

    it "is false when the record has no depositing institute" do
      record.depositing_institute = nil
      expect(formatter.valid?(record)).to be false
    end

    it "is false when the record has no assets" do
      record.assets_size = 0
      expect(formatter.valid?(record)).to be false
    end

    it "is true when every condition is satisfied" do
      expect(formatter.valid?(record)).to be true
    end
  end

  describe "#encode" do
    it "returns an empty string when the record is invalid" do
      record.published = false

      expect(formatter.encode(model, record)).to eq("")
    end

    context "with a valid record" do
      let(:xml) { formatter.encode(model, record) }

      it "renders the resource root with its namespaces" do
        expect(xml).to include("<resource")
        expect(xml).to include('xmlns:oaire="http://namespace.openaire.eu/schema/oaire/"')
      end

      it "renders an alternateIdentifier pointing at the catalog page" do
        expect(xml).to include('identifierType="URL"')
        expect(xml).to include("https://repository.dri.ie/catalog/abc123")
      end

      it "does not render a datacite:identifier when there is no doi" do
        expect(xml).not_to include('identifierType="DOI"')
      end

      it "renders a datacite:identifier when a doi is found" do
        doi = double("doi", doi: "10.1234/abc")
        allow(DataciteDoi).to receive(:find_by).with(object_id: "abc123").and_return(doi)

        expect(xml).to include('identifierType="DOI"')
        expect(xml).to include("10.1234/abc")
      end

      it "renders each creator" do
        expect(xml).to include("<datacite:creatorName>A. Author</datacite:creatorName>")
      end

      it "renders each title" do
        expect(xml).to include("<datacite:title>A Title</datacite:title>")
      end

      it "renders each description" do
        expect(xml).to include("<dc:description>A description</dc:description>")
      end

      it "renders each rights statement prefixed with 'Rights:'" do
        expect(xml).to include("<dc:description>Rights: Some rights statement</dc:description>")
      end

      it "renders a copyright description line when the record has a copyright with a url" do
        record.copyright = double("copyright", present?: true, url: "https://copyright.example/holder", name: "Holder")

        expect(xml).to include("Holder https://copyright.example/holder")
      end

      it "renders the depositing institute as the RightsHolder contributor" do
        expect(xml).to include('contributorType="RightsHolder"')
        expect(xml).to include("<datacite:contributorName>Example Institute</datacite:contributorName>")
      end

      it "renders the access rights for the record's visibility" do
        expect(xml).to include('rightsURI="http://purl.org/coar/access_right/c_abf2"')
        expect(xml).to include("open access")
      end

      it "renders the license condition" do
        expect(xml).to include('<oaire:licenseCondition uri="https://licence.example/cc-by">CC-BY</oaire:licenseCondition>')
      end

      it "renders each subject" do
        expect(xml).to include("<datacite:subject>History</datacite:subject>")
      end

      it "renders the resource type" do
        expect(xml).to include('resourceTypeGeneral="literature"')
        expect(xml).to include(">text</oaire:resourceType>")
      end
    end

    context "when the record has no licence" do
      it "does not render a licenseCondition element" do
        record.licence = nil

        expect(formatter.encode(model, record)).not_to include("licenseCondition")
      end
    end

    context "when the record has no subjects" do
      it "does not render a subjects element" do
        record["subject_tesim"] = []

        expect(formatter.encode(model, record)).not_to include("datacite:subjects")
      end
    end

    context "when the record's visibility does not map to any access right" do
      it "does not render a datacite:rights element" do
        record.visibility = "embargoed"

        expect(formatter.encode(model, record)).not_to include("datacite:rights")
      end
    end
  end

  describe "#parse_published_at" do
    it "delegates to PublishedDateResolver.parse_published_at" do
      expect(DRI::Formatters::OpenAire::PublishedDateResolver).to receive(:parse_published_at).with(record).and_return("2020-01-15")

      expect(formatter.parse_published_at(record)).to eq("2020-01-15")
    end
  end
end
