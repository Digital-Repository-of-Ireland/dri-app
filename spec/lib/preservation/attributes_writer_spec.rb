# frozen_string_literal: true

require "rails_helper"

RSpec.describe Preservation::AttributesWriter do
  let(:tmp_dir) { Dir.mktmpdir }

  let(:access_control) do
    double(
      "access_control",
      attributes: {
        "id" => "ac1",
        "digital_object_type" => "x",
        "digital_object_id" => "y",
        "discover_groups" => ["public"]
      }
    )
  end

  let(:object) do
    double(
      "object",
      alternate_id: "abc12",
      attributes: { "title" => ["A Title"] },
      access_control: access_control,
      governing_collection: nil
    )
  end

  before { allow(Settings.dri).to receive(:files).and_return(tmp_dir) }
  after { FileUtils.remove_dir(tmp_dir, force: true) }

  subject(:writer) { described_class.new(object, 1) }

  describe "#attributes_path" do
    it "points at attributes.json inside the metadata directory for this version" do
      expect(writer.attributes_path).to end_with("attributes.json")
      expect(writer.attributes_path).to include(File.join("data", "metadata"))
    end
  end

  describe "#datastream_path" do
    it "points at <name>.xml inside the metadata directory for this version" do
      expect(writer.datastream_path("descMetadata")).to end_with("descMetadata.xml")
    end
  end

  describe "#write_attributes" do
    before { FileUtils.mkdir_p(File.dirname(writer.attributes_path)) }

    it "writes a JSON attributes file including the object's own attributes" do
      expect(writer.write_attributes).to be true

      data = JSON.parse(File.read(writer.attributes_path))
      expect(data["title"]).to eq(["A Title"])
    end

    it "includes the alternate_identifier" do
      writer.write_attributes

      data = JSON.parse(File.read(writer.attributes_path))
      expect(data["alternate_identifier"]).to eq("abc12")
    end

    it "includes access_control attributes, excluding id/digital_object_type/digital_object_id" do
      writer.write_attributes

      data = JSON.parse(File.read(writer.attributes_path))
      expect(data["access_control"]).to eq("discover_groups" => ["public"])
      expect(data["access_control"]).not_to have_key("id")
      expect(data["access_control"]).not_to have_key("digital_object_type")
      expect(data["access_control"]).not_to have_key("digital_object_id")
    end

    it "includes the governing collection's alternate id when the object has one" do
      collection = double("collection", alternate_id: "col1")
      allow(object).to receive(:governing_collection).and_return(collection)

      writer.write_attributes

      data = JSON.parse(File.read(writer.attributes_path))
      expect(data["governing_collection_alternate_identifier"]).to eq("col1")
    end

    it "omits the governing collection key entirely when the object has none" do
      writer.write_attributes

      data = JSON.parse(File.read(writer.attributes_path))
      expect(data).not_to have_key("governing_collection_alternate_identifier")
    end

    it "returns false (rather than raising) when writing fails" do
      allow(File).to receive(:write).and_raise(Errno::ENOENT)

      expect(writer.write_attributes).to be false
    end
  end

  describe "#write_datastream" do
    before { FileUtils.mkdir_p(File.dirname(writer.datastream_path("descMetadata"))) }

    it "writes the datastream's xml content to <name>.xml" do
      datastream = double("datastream", to_xml: "<xml>hi</xml>")

      expect(writer.write_datastream("descMetadata", datastream)).to be true
      expect(File.read(writer.datastream_path("descMetadata"))).to eq("<xml>hi</xml>")
    end

    it "returns nil without writing anything when the datastream has no xml content" do
      datastream = double("datastream", to_xml: nil)

      expect(writer.write_datastream("descMetadata", datastream)).to be_nil
      expect(File.exist?(writer.datastream_path("descMetadata"))).to be false
    end

    it "returns false (rather than raising) when writing fails" do
      datastream = double("datastream", to_xml: "<xml/>")
      allow(File).to receive(:write).and_raise(Errno::ENOENT)

      expect(writer.write_datastream("descMetadata", datastream)).to be false
    end
  end
end
