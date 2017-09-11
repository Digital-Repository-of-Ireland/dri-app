require 'rails_helper'

describe "master file access" do

  before :each do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @collection = FactoryGirl.create(:collection)

    @object = FactoryGirl.create(:sound)
    @object.governing_collection = @collection
    @object.save

    @gf = DRI::GenericFile.new
    @gf.digital_object = @object
    @gf.save
  end

  after :each do
    @collection.destroy
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  it "object should set file access" do
    @object.master_file_access = "public"
    expect(@gf.public?).to be true

    @object.master_file_access = "private"
    expect(@gf.private?).to be true
  end

  it "should inherit the collection value" do
    expect(@gf.public?).to be false
    @collection.master_file_access = "public"
    
    expect(@gf.public?).to be true
  end
 
  it "should take the object value over the collection" do
    @collection.master_file_access = "public"
    expect(@gf.public?).to be true
    
    @object.master_file_access = "private"
    expect(@gf.public?).to be false
    expect(@gf.private?).to be true
  end

  it "should allow object to be set to inherit" do
    @collection.master_file_access = "public"
    expect(@gf.public?).to be true
    
    @object.master_file_access = "private"
    expect(@gf.public?).to be false
    expect(@gf.private?).to be true

    @object.master_file_access = "inherit"
    expect(@gf.public?).to be true
  end

end
