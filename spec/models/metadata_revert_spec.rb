require 'rails_helper'

describe DRI::DigitalObject do

  it "should not overwrite object changes on save" do
    @t = DRI::DigitalObject.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creation_date = ["null"]
    @t.published_date = ["null"]
    @t.date = ["null"]
    @t.description = ["A fake object"]
    @t.creator = ["A Test"]
    @t.type = ["Image"]

    @t.save
    @t.title.first.should == "A fake record"

    @t.title = ["An edited record"]
    @t.save
    @t.title.first.should == "An edited record"
  end

  it "should not overwrite object changes on reload" do
    @t = DRI::DigitalObject.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creation_date = ["null"]
    @t.published_date = ["null"]
    @t.date = ["null"]
    @t.description = ["A fake object"]
    @t.creator = ["A Test"]
    @t.type = ["Image"]

    @t.save
    @t.title.first.should == "A fake record"

    @t.title = ["An edited record"]
    @t.save
    @t.reload
    @t.title.first.should == "An edited record" 
  end

  it "should not overwrite mods object changes on save" do
    @t = DRI::DigitalObject.with_standard :mods
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creation_date = ["null"]
    @t.published_date = ["null"]
    @t.description = ["A fake object"]
    @t.creator = ["A Test"]
    @t.resource_type = ["Image"]
    @t.mods_id_local = "test"

    @t.save
    @t.title.first.should == "A fake record"

    @t.title = ["An edited record"]
    @t.save
    @t.title.first.should == "An edited record"
  end

  it "should not overwrite mods object changes on reload" do
    @t = DRI::Mods.new
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creation_date = ["null"]
    @t.published_date = ["null"]
    @t.description = ["A fake object"]
    @t.creator = ["A Test"]
    @t.resource_type = ["Image"]
    @t.mods_id_local = "test"

    @t.save
    @t.title.first.should == "A fake record"

    @t.title = ["An edited record"]
    @t.save
    @t.reload
    @t.title.first.should == "An edited record"
  end

  it "should not overwrite mods values on save" do
    @t = DRI::Mods.new
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creation_date = ["null"]
    @t.published_date = ["null"]
    @t.description = ["A fake object"]
    @t.creator = ["A Test"]
    @t.resource_type = ["Image"]
    @t.mods_id_local = "test"

    @t.save
    @t.creator.first.should == "A Test"

    @t.creator = ["A New Creator"]
    #@t.description = ["An edited fake object"]
    @t.save
    @t.reload
    @t.creator.first.should == "A New Creator"
    #@t.description.first.should == "An edited fake object"
  end
 
  it "should not overwrite dc creator on save" do
    @t = DRI::QualifiedDublinCore.new
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creation_date = ["null"]
    @t.published_date = ["null"]
    @t.description = ["A fake object"]
    @t.creator = ["A Test"]
    @t.type = ["Image"]

    @t.save
    @t.creator.first.should == "A Test"

    @t.creator = ["A New Creator"]
    @t.save
    @t.reload
    @t.creator.first.should == "A New Creator"
  end
 
  after(:each) do
    unless @t.new_record?
      @t.destroy
    end
  end

end
