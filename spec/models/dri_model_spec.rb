require 'spec_helper'

describe DRI::Model do
  it "should have an audio type with the level 1 required metadata fields" do
    t = DRI::Model::Audio.new
    t.title = nil
    t.rights = nil
    t.language = nil
    t.should_not be_valid
  end
end
