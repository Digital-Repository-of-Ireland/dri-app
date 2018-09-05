describe "master file access" do

  before :each do
    @collection = DRI::Batch.with_standard(:qdc)
    @collection.title = ["Test Associations Collection"]
    @collection.description = ["Description"]
    @collection.rights = ["Rights"]
    @collection.type = ["Collection"]
    @collection.creation_date = ["2015-04-01"]

    @collection.save

    @object = DRI::Batch.with_standard(:qdc)
    @object.title = ["Test Associations Object"]
    @object.description = ["Description"]
    @object.rights = ["Rights"]
    @object.type = ["Sound"]
    @object.creation_date = ["2015-04-01"]

    @object.governing_collection = @collection
    @object.save

    @gf = DRI::GenericFile.new
    @gf.batch = @object
    @gf.save
  end

  after :each do
    @gf.delete
    @object.delete
    @collection.delete
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
