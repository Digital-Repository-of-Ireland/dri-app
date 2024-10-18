require 'rails_helper'

RSpec.describe DRI::Catalog, type: :controller do
  # Setup a mock controller to include the DRI::Catalog concern
  controller(ApplicationController) do
    include DRI::Catalog
  end

  # Mocking a document object to simulate the data used in the controller
  let(:mock_document) { double("Document", dataset?: "Organization", depositing_institute: nil) }

  describe "#should_render_organizations?" do
    it "returns true when dataset is 'Organization'" do
      expect(subject.send(:should_render_organizations?, mock_document)).to be true
    end

    it "returns true when dataset is nil" do
      allow(mock_document).to receive(:dataset?).and_return(nil)
      expect(subject.send(:should_render_organizations?, mock_document)).to be true
    end

    it "returns false when dataset is not 'Organization'" do
      allow(mock_document).to receive(:dataset?).and_return("Research")
      expect(subject.send(:should_render_organizations?, mock_document)).to be false
    end
  end

  describe "#should_render_orgs_and_sponsors?" do
    it "returns true when dataset is 'Organization'" do
      expect(subject.send(:should_render_orgs_and_sponsors?, mock_document)).to be true
    end

    it "returns true when depositing institute is present" do
      allow(mock_document).to receive(:depositing_institute).and_return('Some Institute')
      expect(subject.send(:should_render_orgs_and_sponsors?, mock_document)).to be true
    end

    it "returns false when dataset is not 'Organization' and depositing institute is nil" do
      allow(mock_document).to receive(:dataset?).and_return("Research")
      expect(subject.send(:should_render_orgs_and_sponsors?, mock_document)).to be false
    end
  end

  describe "#available_timelines_from_facets" do
    let(:mock_response) { { 'facet_counts' => { 'facet_fields' => { 'sdate_range_start_isi' => ['2000'] } } } }

    before do
      subject.instance_variable_set(:@response, mock_response)
    end

    it "returns available timeline fields when facet is present" do
      expect(subject.send(:available_timelines_from_facets)).to include('sdate')
    end

    it "returns an empty array when no facets are present" do
      mock_response['facet_counts']['facet_fields'] = {}
      expect(subject.send(:available_timelines_from_facets)).to be_empty
    end
  end
end
