require "rails_helper"

describe Institute do

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @collection = FactoryBot.create(:collection)
    @institute = Institute.new
    @institute.name = "Test Institute"
    @institute.url = "http://www.test.ie"
    @institute.save
  end

  after(:each) do
    @collection.delete
    @institute.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  it "should allow for a logo to be added" do
    uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "sample_logo.png"), "image/png")
    expect(Institute.new.add_logo(uploaded, { name: 'Test logo', url: @institute.url })).to be true
  end

  it "should return the collections it is associated with" do
    @collection.institute = [@institute.name]
    @collection.save
      
    expect(@institute.collections.first[:id]).to eq @collection.id
  end

  it "should return empty array if not associated" do
    expect(@institute.collections).to eq([])
  end
end
