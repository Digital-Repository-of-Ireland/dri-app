require 'rails_helper'

RSpec.describe DRI::Catalog, type: :controller do
  # Setup a mock controller to include the DRI::Catalog concern
  controller(ApplicationController) do
    include DRI::Catalog
  end

  # Mocking a document object to simulate the data used in the controller
  let(:mock_document) { double("Document", dataset?: "Organization", depositing_institute: nil) }

  describe "#should_render_depositing_organization?" do
    it "returns true when not a dataset" do
      allow(mock_document).to receive(:dataset?).and_return(false)
      expect(subject.send(:should_render_depositing_organization?, mock_document)).to be true
    end

    it "returns false when research dataset" do
      allow(mock_document).to receive(:dataset?).and_return("true")
      expect(subject.send(:should_render_depositing_organization?, mock_document)).to be false
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
