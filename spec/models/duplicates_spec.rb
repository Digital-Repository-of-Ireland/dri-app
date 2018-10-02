describe 'DRI::Solr::Document::Collection' do
  include DRI::Duplicable
  
  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
  end

  after(:each) do
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  before(:each) do
    @collection = FactoryBot.create(:collection)
   
    @object = FactoryBot.create(:sound) 
    @object[:status] = "draft"
    checksum_metadata(@object)
    @object.save

    @object2 = FactoryBot.create(:sound) 
    @object2[:status] = "draft"
    checksum_metadata(@object2)
    @object2.save

    @object3 = FactoryBot.create(:sound) 
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
  end

  it 'should return a count of duplicates' do
    doc = SolrDocument.new(@collection.to_solr)

    expect(doc.duplicate_total).to eq(2)
  end

  it 'should get the solr documents of duplicates' do
    doc = SolrDocument.new(@collection.to_solr)

    duplicates = doc.duplicates[1]
    ids = []
    duplicates.each { |dup| ids << dup.id }

    expect(ids.count).to eq(2)
    expect(ids).to include(@object.id)
    expect(ids).to include(@object2.id)
    expect(ids).to_not include(@object3.id)
  end

end

     
  
