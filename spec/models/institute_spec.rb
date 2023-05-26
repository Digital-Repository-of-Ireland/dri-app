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
    @collection.destroy
    @institute.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  it "should allow for a logo to be added" do
    uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "sample_logo.png"), "image/png")
    expect(@institute.add_logo(uploaded)).to be true
  end

  it "should return the collections it is associated with" do
    @collection.institute = [@institute.name]
    @collection.save

    expect(@institute.collections.first[:id]).to eq @collection.alternate_id
  end

  it "should return empty array if not associated" do
    expect(@institute.collections).to eq([])
  end

  it "should accept an organisation manager" do
    user = FactoryBot.create(:organisation_manager)
    @institute.manager = user.email
    expect(@institute.org_manager).to eq(user)

    @institute.manager = user
    expect(@institute.org_manager).to eq(user)
  end

  it "should not accept a non org manager as manager" do
    user = FactoryBot.create(:user)
    expect { @institute.manager = user.email }.to raise_error(ArgumentError)
  end

  it "should not save a manager for an organisation that is not persisted" do
    i = Institute.new
    user = FactoryBot.create(:organisation_manager)
    expect { i.manager = user.email }.not_to change { OrganisationUser.count }
  end 
end
