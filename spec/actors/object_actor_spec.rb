require 'rails_helper'

describe 'DRI::Object::Actor' do
  include DRI::MetadataBehaviour
  
  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
    
    @user = FactoryGirl.create(:user)

    @collection = FactoryGirl.create(:collection)
   
    @object = FactoryGirl.create(:sound) 
    @object[:status] = "draft"
    checksum_metadata(@object)
    @object.save

    @object2 = FactoryGirl.create(:sound) 
    @object2[:status] = "draft"
    checksum_metadata(@object2)
    @object2.save

    @object3 = FactoryGirl.create(:sound) 
    @object3[:status] = "draft"
    @object3[:title] = ["Not a Duplicate"]
    checksum_metadata(@object3)
    @object3.save

    @collection.governed_items << @object
    @collection.governed_items << @object2
    @collection.governed_items << @object3
  end

  after(:each) do
    @collection.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  it 'should return duplicates' do
    actor = DRI::Object::Actor.new(@object, @user)

    duplicates = actor.find_duplicates
    
    expect(duplicates.length).to eq(1)
    expect(duplicates.first['id']).to eq(@object2.id)
  end
end
