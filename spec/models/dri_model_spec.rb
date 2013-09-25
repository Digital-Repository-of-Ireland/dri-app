require 'spec_helper'

describe Batch do
  it "should have an audio type with the level 1 required metadata fields" do
    t = Batch.new
    t.title = nil
    t.rights = nil
    t.language = nil
    t.object_type = [ "Audio"]
    t.should_not be_valid
  end
end
