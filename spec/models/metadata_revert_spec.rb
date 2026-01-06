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
    expect(@t.title.first).to eql "A fake record"

    @t.title = ["An edited record"]
    @t.save
    expect(@t.title.first).to eql "An edited record"
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
    expect(@t.title.first).to eql "A fake record"

    @t.title = ["An edited record"]
    @t.save
    @t.reload
    expect(@t.title.first).to eql "An edited record" 
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
    expect(@t.title.first).to eql "A fake record"

    @t.title = ["An edited record"]
    @t.save
    expect(@t.title.first).to eql "An edited record"
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
    expect(@t.title.first).to eql "A fake record"

    @t.title = ["An edited record"]
    @t.save
    @t.reload
    expect(@t.title.first).to eql "An edited record"
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
    expect(@t.creator.first).to eql "A Test"

    @t.creator = ["A New Creator"]
    #@t.description = ["An edited fake object"]
    @t.save
    @t.reload
    expect(@t.creator.first).to eql "A New Creator"
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
    expect(@t.creator.first).to eql "A Test"

    @t.creator = ["A New Creator"]
    @t.save
    @t.reload
    expect(@t.creator.first).to eql "A New Creator"
  end
 
  after(:each) do
    unless @t.new_record?
      @t.destroy
    end
  end
end
