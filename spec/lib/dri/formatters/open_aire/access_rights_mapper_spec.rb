# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::OpenAire::AccessRightsMapper do
  describe ".for" do
    it "maps 'public' to open access" do
      expect(described_class.for("public")).to eq(uri: "http://purl.org/coar/access_right/c_abf2", label: "open access")
    end

    it "maps 'restricted' to metadata only access" do
      expect(described_class.for("restricted")).to eq(uri: "http://purl.org/coar/access_right/c_14cb", label: "metadata only access")
    end

    it "maps 'logged-in' to restricted access" do
      expect(described_class.for("logged-in")).to eq(uri: "http://purl.org/coar/access_right/c_16ec", label: "restricted access")
    end

    it "returns nil for an unrecognised visibility value" do
      expect(described_class.for("embargoed")).to be_nil
    end

    it "returns nil for a nil visibility" do
      expect(described_class.for(nil)).to be_nil
    end
  end
end
