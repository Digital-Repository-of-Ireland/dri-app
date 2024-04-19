require 'rails_helper'

describe CollectionConfig do
  it "should return false if no config exists" do
    expect(CollectionConfig.can_export?('test')).to be false
  end

  context "With configuration" do
    let(:config) { CollectionConfig.create(collection_id: 'test') }

    it "should return false for export if config set to false" do
      config.allow_export = false
      config.save
      expect(CollectionConfig.can_export?('test')).to be false
    end

    it "should return true for export if config set to true" do
      config.allow_export =  true
      config.save
      expect(CollectionConfig.can_export?('test')).to be true
    end
  end    
end