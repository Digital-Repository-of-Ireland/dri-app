require 'rails_helper'

describe "StorageService" do

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    
    @collection = FactoryGirl.create(:collection)

    @object = DRI::DigitalObject.with_standard :qdc
    @object[:title] = ["An Audio Title"]
    @object[:rights] = ["This is a statement about the rights associated with this object"]
    @object[:role_hst] = ["Collins, Michael"]
    @object[:contributor] = ["DeValera, Eamonn", "Connolly, James"]
    @object[:language] = ["ga"]
    @object[:description] = ["This is an Audio file"]
    @object[:published_date] = ["1916-04-01"]
    @object[:creation_date] = ["1916-01-01"]
    @object[:source] = ["CD nnn nuig"]
    @object[:geographical_coverage] = ["Dublin"]
    @object[:temporal_coverage] = ["1900s"]
    @object[:subject] = ["Ireland","something else"]
    @object[:resource_type] = ["Sound"]
    @object[:status] = "draft"
    @object.save

    @collection.governed_items << @object    
    @collection.save
    
    @gf = DRI::GenericFile.new
    @gf.apply_depositor_metadata(@login_user)
    @gf.digital_object = @object
    @gf.save
  end

  after(:each) do
    @gf.delete
    @object.delete
    @collection.delete

    @login_user.delete
  end

  it "should store a surrogate" do
    storage = StorageService.new
    storage.create_bucket(@object.noid)
    storage.store_surrogate(@object.noid, File.join(fixture_path, "SAMPLEA.mp3"), "#{@gf.noid}_mp3.mp3")

    expect(storage.surrogate_exists?(@object.noid, "#{@gf.noid}_mp3")).to be true
  end

  it "should return a uri to the file" do
    storage = StorageService.new
    storage.create_bucket(@object.noid)
    storage.store_surrogate(@object.noid, File.join(fixture_path, "SAMPLEA.mp3"), "#{@gf.noid}_mp3.mp3")

    uri = storage.surrogate_url(@object.noid, "#{@gf.noid}_mp3")
    
    expect(File.basename(URI.parse(uri).path)).to be == "#{@gf.noid}_mp3.mp3"
  end

  it "should list surrogates" do
    storage = StorageService.new
    storage.create_bucket(@object.noid)
    storage.store_surrogate(@object.noid, File.join(fixture_path, "SAMPLEA.mp3"), "#{@gf.noid}_mp3.mp3")

    list = storage.get_surrogates(@object.noid, @gf.noid)

    expect(list.key?('mp3')).to be true
    expect { URI.parse(list['mp3']) }.to_not raise_error
  end

  it "should delete surrogates" do
    storage = StorageService.new
    storage.create_bucket(@object.noid)
    storage.store_surrogate(@object.noid, File.join(fixture_path, "SAMPLEA.mp3"), "#{@gf.noid}_mp3.mp3")

    expect(storage.surrogate_exists?(@object.noid, "#{@gf.noid}_mp3")).to be true

    storage.delete_surrogates(@object.noid, @gf.noid)
    expect(storage.surrogate_exists?(@object.noid, "#{@gf.noid}_mp3")).to be_nil
  end 

  it "should store a public file" do
    storage = StorageService.new
    storage.create_bucket(@object.noid)
    response = storage.store_file(@object.noid, File.join(fixture_path, "sample_image.png"), "sample_image.png")

    expect(response).to be true
  end

  it "should return a public file url" do
    storage = StorageService.new
    storage.create_bucket(@object.noid)
    storage.store_file(@object.noid, File.join(fixture_path, "sample_image.png"), "sample_image.png")

    expect{ URI.parse(storage.file_url(@object.noid, 'sample_image.png')) }.not_to raise_error
  end

end
