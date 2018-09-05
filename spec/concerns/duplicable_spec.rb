describe 'DRI::Duplicable' do

  let(:duplicable_test) { Class.new do
    include DRI::Duplicable
  end
  }

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @user = FactoryBot.create(:user)

    @collection = FactoryBot.create(:collection)

    @object = FactoryBot.create(:sound)
    @object[:status] = "draft"
    @object.save

    @object2 = FactoryBot.create(:sound)
    @object2[:status] = "draft"
    @object2.save

    @object3 = FactoryBot.create(:sound)
    @object3[:status] = "draft"
    @object3[:title] = ["Not a Duplicate"]
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
    duplicable_test.new.checksum_metadata(@object)
    duplicable_test.new.checksum_metadata(@object2)
    duplicable_test.new.checksum_metadata(@object3)
    @object.save
    @object2.save
    @object3.save

    duplicates = duplicable_test.new.find_object_duplicates(@object)

    expect(duplicates.length).to eq(1)
    expect(duplicates.first['id']).to eq(@object2.id)
  end
end
