# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Linkset::LicenceLink do
  describe ".for" do
    it "returns the licence url when the document has a licence responding to #url" do
      licence = double("licence", url: "https://licence.example/cc-by")
      document = double("document", licence: licence)

      expect(described_class.for(document)).to eq("https://licence.example/cc-by")
    end

    it "returns nil when the document has no licence" do
      document = double("document", licence: nil)

      expect(described_class.for(document)).to be_nil
    end

    it "returns nil when the licence does not respond to #url" do
      licence = double("licence")
      document = double("document", licence: licence)

      expect(described_class.for(document)).to be_nil
    end
  end
end
