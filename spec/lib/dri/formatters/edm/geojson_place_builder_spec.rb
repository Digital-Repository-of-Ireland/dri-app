# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Edm::GeojsonPlaceBuilder do
  let(:xml) { Builder::XmlMarkup.new }

  def geojson_for(properties: {}, coordinates: [-6.2, 53.3], type: "Point")
    {
      "geometry" => { "type" => type, "coordinates" => coordinates },
      "properties" => properties
    }.to_json
  end

  it "writes an edm:Place with lat/long and bilingual prefLabels" do
    record = { "geojson_ssim" => [geojson_for(properties: { "nameGA" => "Baile Atha Cliath", "nameEN" => "Dublin" })] }

    described_class.new(record).write(xml)
    output = xml.target!

    expect(output).to include("<edm:Place")
    expect(output).to include('xml:lang="ga"')
    expect(output).to include("Baile Atha Cliath")
    expect(output).to include('xml:lang="en"')
    expect(output).to include("Dublin")
    expect(output).to include("<wgs84_pos:lat>53.3</wgs84_pos:lat>")
    expect(output).to include("<wgs84_pos:long>-6.2</wgs84_pos:long>")
  end

  it "falls back to placename when nameEN is absent" do
    record = { "geojson_ssim" => [geojson_for(properties: { "placename" => "Dublin" })] }

    described_class.new(record).write(xml)

    expect(xml.target!).to include("Dublin")
  end

  it "uses the properties uri for the rdf:about identifier when present" do
    record = { "geojson_ssim" => [geojson_for(properties: { "uri" => "http://example.org/place/1" })] }

    described_class.new(record).write(xml)

    expect(xml.target!).to include('rdf:about="#http://example.org/place/1"')
  end

  it "strips spaces from the fallback identifier when there is no uri or placename" do
    record = { "geojson_ssim" => [geojson_for(properties: {}, coordinates: [-6.2, 53.3])] }

    described_class.new(record).write(xml)

    expect(xml.target!).to include('rdf:about="#[-6.2,53.3]"')
  end

  it "skips non-Point geometries" do
    record = { "geojson_ssim" => [geojson_for(type: "Polygon")] }

    described_class.new(record).write(xml)

    expect(xml.target!).to eq("")
  end

  it "skips points missing latitude or longitude" do
    record = { "geojson_ssim" => [geojson_for(coordinates: [nil, nil])] }

    described_class.new(record).write(xml)

    expect(xml.target!).to eq("")
  end

  it "does nothing when geojson_ssim is absent" do
    record = {}

    described_class.new(record).write(xml)

    expect(xml.target!).to eq("")
  end

  it "writes one edm:Place per geojson entry" do
    record = {
      "geojson_ssim" => [
        geojson_for(properties: { "placename" => "Dublin" }, coordinates: [-6.2, 53.3]),
        geojson_for(properties: { "placename" => "Cork" }, coordinates: [-8.4, 51.9])
      ]
    }

    described_class.new(record).write(xml)

    expect(xml.target!.scan("<edm:Place").size).to eq(2)
  end
end
