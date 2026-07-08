# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::OpenAire::DoiFinder do
  describe ".find" do
    it "looks up the DataciteDoi scoped to the record's id" do
      record = double("record", id: "abc123")
      doi_record = double("doi_record")
      expect(DataciteDoi).to receive(:find_by).with(object_id: "abc123").and_return(doi_record)

      expect(described_class.find(record)).to eq(doi_record)
    end

    it "returns nil when there is no matching doi record" do
      record = double("record", id: "abc123")
      allow(DataciteDoi).to receive(:find_by).with(object_id: "abc123").and_return(nil)

      expect(described_class.find(record)).to be_nil
    end
  end
end
