# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Edm::DcmiParser do
  describe ".parse" do
    it "parses semicolon-separated key=value pairs into a downcased hash" do
      result = described_class.parse("Name=Some Place; North=53.3; East=-6.2")

      expect(result).to eq(
        "name" => "Some Place",
        "north" => "53.3",
        "east" => "-6.2"
      )
    end

    it "strips whitespace around values" do
      result = described_class.parse("name =  1916  ; start=1916-04-24")

      expect(result["name"]).to eq("1916")
      expect(result["start"]).to eq("1916-04-24")
    end

    it "ignores components with no value" do
      result = described_class.parse("name=1916; junk; start=1916-04-24")

      expect(result.keys).to contain_exactly("name", "start")
    end

    it "returns an empty hash for a blank value" do
      expect(described_class.parse("")).to eq({})
      expect(described_class.parse(nil)).to eq({})
    end
  end

  describe ".valid_period?" do
    it "is true when name and start are present" do
      expect(described_class.valid_period?("name" => "1916", "start" => "1916-04-24")).to be true
    end

    it "is false when start is missing" do
      expect(described_class.valid_period?("name" => "1916")).to be false
    end

    it "is false when name is missing" do
      expect(described_class.valid_period?("start" => "1916-04-24")).to be false
    end

    it "is false for an empty hash" do
      expect(described_class.valid_period?({})).to be false
    end
  end

  describe ".valid_point?" do
    it "is true when name, north and east are present" do
      expect(
        described_class.valid_point?("name" => "Dublin", "north" => "53.3", "east" => "-6.2")
      ).to be true
    end

    it "is false when north is missing" do
      expect(described_class.valid_point?("name" => "Dublin", "east" => "-6.2")).to be false
    end

    it "is false when east is missing" do
      expect(described_class.valid_point?("name" => "Dublin", "north" => "53.3")).to be false
    end

    it "is false for an empty hash" do
      expect(described_class.valid_point?({})).to be false
    end
  end
end
