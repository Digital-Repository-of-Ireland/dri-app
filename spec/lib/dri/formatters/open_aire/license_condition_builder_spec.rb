# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::OpenAire::LicenseConditionBuilder do
  describe ".for" do
    it "uses the licence's own url and name when the url is present" do
      licence = double("licence", url: "https://licence.example/cc-by", name: "CC-BY")
      record = double("record", licence: licence, id: "abc123")

      expect(described_class.for(record)).to eq(uri: "https://licence.example/cc-by", label: "CC-BY")
    end

    it "falls back to the record's catalog url when the licence has no url" do
      licence = double("licence", url: nil, name: "All Rights Reserved")
      record = double("record", licence: licence, id: "abc123")

      expect(described_class.for(record)).to eq(
        uri: "https://repository.dri.ie/catalog/abc123", label: "All Rights Reserved"
      )
    end

    it "falls back to the record's catalog url when the licence's url is blank" do
      licence = double("licence", url: "", name: "All Rights Reserved")
      record = double("record", licence: licence, id: "abc123")

      expect(described_class.for(record)).to eq(
        uri: "https://repository.dri.ie/catalog/abc123", label: "All Rights Reserved"
      )
    end

    it "returns nil when the record has no licence" do
      record = double("record", licence: nil)

      expect(described_class.for(record)).to be_nil
    end
  end
end
