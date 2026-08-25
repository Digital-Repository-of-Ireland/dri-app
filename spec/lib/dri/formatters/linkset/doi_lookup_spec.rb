# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Linkset::DoiLookup do
  let(:document) { double("document", id: "abc123") }

  describe ".resolve" do
    it "returns the doi string when a current, minted doi exists" do
      doi_record = double("doi_record", present?: true, minted?: true, doi: "10.1234/abc")
      allow(DataciteDoi).to receive_message_chain(:where, :current).and_return(doi_record)

      expect(described_class.resolve(document)).to eq("10.1234/abc")
    end

    it "returns nil when there is no current doi record" do
      allow(DataciteDoi).to receive_message_chain(:where, :current).and_return(nil)

      expect(described_class.resolve(document)).to be_nil
    end

    it "returns nil when the doi record exists but has not been minted" do
      doi_record = double("doi_record", present?: true, minted?: false)
      allow(DataciteDoi).to receive_message_chain(:where, :current).and_return(doi_record)

      expect(described_class.resolve(document)).to be_nil
    end

    it "scopes the lookup to the document's id" do
      relation = double("relation")
      expect(DataciteDoi).to receive(:where).with(object_id: "abc123").and_return(relation)
      allow(relation).to receive(:current).and_return(nil)

      described_class.resolve(document)
    end
  end
end
