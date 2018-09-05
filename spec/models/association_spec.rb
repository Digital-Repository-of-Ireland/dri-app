describe "collection associations" do

  before :each do
    @collection = DRI::Batch.with_standard(:qdc)
    @collection.title = ["Test Associations Collection"]
    @collection.description = ["Description"]
    @collection.creator = ["Creator"]
    @collection.rights = ["Rights"]
    @collection.type = ["Collection"]
    @collection.creation_date = ["2015-04-01"]

    @collection.save

    @object = DRI::Batch.with_standard(:qdc)
    @object.title = ["Test Associations Object"]
    @object.description = ["Description"]
    @object.creator = ["Creator"]
    @object.rights = ["Rights"]
    @object.type = ["Sound"]
    @object.creation_date = ["2015-04-01"]

    @object.save
  end

  after :each do
    @collection.delete
  end

  it "should associate from object to collection" do
    @object.governing_collection = @collection
    @object.save
    @collection.reload
    expect(@collection.governed_items).to eq [@object]
   end
    
   it "should associate from collection to object" do
     @collection.governed_items << @object
     @collection.save
     @object.reload
     expect(@object.governing_collection).to eq @collection
   end
  
end
