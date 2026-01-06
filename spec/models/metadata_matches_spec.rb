require "rails_helper"

describe SolrDocument do
  include DRI::Duplicable

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @collection = FactoryBot.create(:collection)
    @collection2 = FactoryBot.create(:collection)

    @object = FactoryBot.create(:sound)
    @object[:status] = "draft"
    checksum_metadata(@object)
    @object.save

    @object2 = FactoryBot.create(:sound)
    @object2[:status] = "draft"
    checksum_metadata(@object2)
    @object2.save

    @object4 = FactoryBot.create(:sound)
    @object4[:status] = "draft"
    checksum_metadata(@object4)
    @object4.save

    @object3 = FactoryBot.create(:sound)
    @object3[:status] = "draft"
    @object3[:title] = ["Not a Duplicate"]
    checksum_metadata(@object3)
    @object3.save

    @collection.governed_items << @object
    @collection.governed_items << @object2
    @collection.governed_items << @object3

    @collection2.governed_items << @object4
  end

  after(:each) do
    @collection.destroy
    @collection2.destroy

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  it 'should return duplicates' do
    doc = SolrDocument.new(@object.to_solr)

    expect(doc.find_metadata_matches.size).to eq(1)
    expect(doc.find_metadata_matches[0].alternate_id).to eq(@object2.alternate_id)
  end
end