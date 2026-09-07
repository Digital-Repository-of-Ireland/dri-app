# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::OpenAire::PublishedDateResolver do
  describe ".resolve" do
    it "uses the parsed 'start' date from published_date_tesim when present" do
      record = double("record")
      allow(record).to receive(:key?).with("published_date_tesim").and_return(true)
      allow(record).to receive(:[]).with("published_date_tesim").and_return(["1916-04-24 - 1916-04-30"])
      allow(DRI::Metadata::Transformations).to receive(:date_range)
        .with("1916-04-24 - 1916-04-30")
        .and_return("start" => "1916-04-24", "end" => "1916-04-30")

      expect(described_class.resolve(record)).to eq("1916-04-24")
    end

    it "falls back to published_at when published_date_tesim is absent" do
      record = double("record")
      allow(record).to receive(:key?).with("published_date_tesim").and_return(false)
      allow(record).to receive(:[]).with("published_at_dttsi").and_return("2020-01-15T00:00:00Z")

      expect(described_class.resolve(record)).to eq("2020-01-15")
    end

    it "falls back to published_at when published_date_tesim is present but blank" do
      record = double("record")
      allow(record).to receive(:key?).with("published_date_tesim").and_return(true)
      allow(record).to receive(:[]).with("published_date_tesim").and_return([])
      allow(record).to receive(:[]).with("published_at_dttsi").and_return("2020-01-15T00:00:00Z")

      expect(described_class.resolve(record)).to eq("2020-01-15")
    end

    it "falls back to published_at when the parsed date range has no 'start' key" do
      record = double("record")
      allow(record).to receive(:key?).with("published_date_tesim").and_return(true)
      allow(record).to receive(:[]).with("published_date_tesim").and_return(["undated"])
      allow(DRI::Metadata::Transformations).to receive(:date_range).with("undated").and_return({})
      allow(record).to receive(:[]).with("published_at_dttsi").and_return("2020-01-15T00:00:00Z")

      expect(described_class.resolve(record)).to eq("2020-01-15")
    end

    it "only looks at the first published_date_tesim value" do
      record = double("record")
      allow(record).to receive(:key?).with("published_date_tesim").and_return(true)
      allow(record).to receive(:[]).with("published_date_tesim").and_return(["first-range", "second-range"])
      expect(DRI::Metadata::Transformations).to receive(:date_range).with("first-range").and_return("start" => "1916-04-24")

      described_class.resolve(record)
    end
  end

  describe ".parse_published_at" do
    it "formats the published_at timestamp as YYYY-MM-DD" do
      record = { "published_at_dttsi" => "2020-01-15T10:30:00Z" }

      expect(described_class.parse_published_at(record)).to eq("2020-01-15")
    end
  end
end
