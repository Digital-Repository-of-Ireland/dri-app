require 'rails_helper'
require 'csv'

describe CatalogController, type: :controller do

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @object = FactoryBot.create(:sound)
    @object[:status] = "draft"
    @object.save
  end

  after(:each) do
    @object.destroy

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  context "exporting CSV" do
    it "should format an object as a CSV" do
      expected_csv = CSV.read(File.join(fixture_path, "export.csv"))
      doc = SolrDocument.find(@object.alternate_id)
      formatter = DRI::Exporters::Csv.new(controller.request.base_url, doc)
      generated_csv = CSV.parse(formatter.format)

      expect(generated_csv[0]).to match_array(expected_csv[0])
      generated_csv[1].pop
      expected_csv[1].pop
      expect(generated_csv[1].drop(1)).to match_array(expected_csv[1].drop(1))
    end

    it "should accept fields to output" do
      requested_fields = ['title', 'subject', 'temporal_coverage']
      expected_titles = ["Id", "Title", "Subjects", "Subjects (Temporal)", "Licence", "Copyright", "Url"]
      object_doc = SolrDocument.new(@object.to_solr)
      formatter = DRI::Exporters::Csv.new(controller.request.base_url, object_doc, { fields: requested_fields })
      generated_csv = CSV.parse(formatter.format)

      expect(generated_csv[0]).to match_array(expected_titles)
      expect(generated_csv[1][0]).to eql(@object.alternate_id)
      expect(generated_csv[1][1]).to eql(@object.title.join('|'))
      expect(generated_csv[1][2]).to eql(@object.subject.join('|'))
      expect(generated_csv[1][3]).to eql(object_doc['temporal_coverage_tesim'].join('|'))
    end
  end

end
