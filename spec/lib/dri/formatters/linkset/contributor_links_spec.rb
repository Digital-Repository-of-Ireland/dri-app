# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Linkset::ContributorLinks do
  describe ".for" do
    it "returns nil when the document has no contributor_tesim field" do
      document = { "contributor_tesim" => nil }

      expect(described_class.for(document)).to be_nil
    end

    it "returns nil when contributor_tesim is an empty array" do
      document = { "contributor_tesim" => [] }

      expect(described_class.for(document)).to be_nil
    end

    it "extracts an orcid.org url embedded anywhere in an entry" do
      document = { "contributor_tesim" => ["Some Author https://orcid.org/0000-0001-2345-6789"] }

      expect(described_class.for(document)).to eq(["https://orcid.org/0000-0001-2345-6789"])
    end

    it "does not capture trailing punctuation like a closing parenthesis" do
      document = { "contributor_tesim" => ["Some Author (https://orcid.org/0000-0001-2345-6789)"] }

      expect(described_class.for(document)).to eq(["https://orcid.org/0000-0001-2345-6789"])
    end

    it "matches an orcid iD whose checksum digit is X" do
      document = { "contributor_tesim" => ["Some Author https://orcid.org/0000-0001-2345-678X"] }

      expect(described_class.for(document)).to eq(["https://orcid.org/0000-0001-2345-678X"])
    end

    it "drops entries with no orcid url" do
      document = { "contributor_tesim" => ["Plain Author Name", "https://orcid.org/0000-0001-2345-6789"] }

      expect(described_class.for(document)).to eq(["https://orcid.org/0000-0001-2345-6789"])
    end

    it "returns an empty array when no entries contain an orcid url" do
      document = { "contributor_tesim" => ["Plain Author Name"] }

      expect(described_class.for(document)).to eq([])
    end

    it "returns one entry per contributor, in order" do
      document = {
        "contributor_tesim" => [
          "https://orcid.org/0000-0001-1111-1111",
          "https://orcid.org/0000-0002-2222-2222"
        ]
      }

      expect(described_class.for(document)).to eq(
        ["https://orcid.org/0000-0001-1111-1111", "https://orcid.org/0000-0002-2222-2222"]
      )
    end
  end
end