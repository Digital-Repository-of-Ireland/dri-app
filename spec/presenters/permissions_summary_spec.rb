# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::AccessControls::PermissionsSummary do
  def document_with(read_groups:, read_master:)
    double("document", ancestor_field: read_groups, read_master?: read_master)
  end

  describe ".for" do
    it "labels registered-only read access as logged-in" do
      document = document_with(read_groups: ["registered"], read_master: false)

      result = described_class.for(document)

      expect(result[:read_access]).to eq("logged-in")
      expect(result[:read_label]).to be_present
    end

    it "labels public read access as public" do
      document = document_with(read_groups: ["public"], read_master: false)

      result = described_class.for(document)

      expect(result[:read_access]).to eq("public")
      expect(result[:read_label]).to be_present
    end

    it "labels any other read group combination as restricted" do
      document = document_with(read_groups: ["some-custom-group"], read_master: false)

      result = described_class.for(document)

      expect(result[:read_access]).to eq("restricted")
      expect(result[:read_label]).to be_present
    end

    it "labels an empty read group list as restricted" do
      document = document_with(read_groups: [], read_master: false)

      expect(described_class.for(document)[:read_access]).to eq("restricted")
    end

    it "labels a nil read group value as restricted" do
      document = document_with(read_groups: nil, read_master: false)

      expect(described_class.for(document)[:read_access]).to eq("restricted")
    end

    it "labels asset access as public when read_master? is true" do
      document = document_with(read_groups: ["public"], read_master: true)

      result = described_class.for(document)

      expect(result[:assets]).to eq("public")
      expect(result[:assets_label]).to be_present
    end

    it "labels asset access as private when read_master? is false" do
      document = document_with(read_groups: ["public"], read_master: false)

      result = described_class.for(document)

      expect(result[:assets]).to eq("private")
      expect(result[:assets_label]).to be_present
    end

    it "queries the read_access_group_ssim ancestor field specifically" do
      document = double("document", read_master?: false)
      expect(document).to receive(:ancestor_field).with("read_access_group_ssim").and_return(["public"])

      described_class.for(document)
    end
  end
end
