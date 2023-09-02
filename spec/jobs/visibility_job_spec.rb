require 'rails_helper'
require 'solr/query'

describe 'VisibilityJob' do

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:collection_manager)
    @collection = FactoryBot.create(:collection)
    
    @object = FactoryBot.create(:sound)
    @object[:status] = "reviewed"
    @object.save

    @collection.governed_items << @object
    @collection.save
  end

  after(:each) do
    @collection.destroy

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'run' do
    it "should set a collection\'s visibility" do
      @collection.read_groups_string = "restricted"
      @collection.save

      VisibilityJob.perform(@collection.alternate_id)

      @collection.reload
      @object.reload

      expect(@collection.visibility).to eql('restricted')
      expect(@object.visibility).to eql('restricted')
    end

    it "should set an object\'s visibility" do
      @object.read_groups_string = "public"
      @object.save

      VisibilityJob.perform(@object.alternate_id)

      @object.reload
      expect(@object.visibility).to eql('public')
    end

    it "should not change an object\'s visibility" do
      @object.read_groups_string = "public"
      @object.save
      VisibilityJob.perform(@object.alternate_id)

      @object.reload
      expect(@object.visibility).to eql('public')
      
      @collection.read_groups_string = "restricted"
      @collection.save

      VisibilityJob.perform(@collection.alternate_id)

      @object.reload
      @collection.reload
      expect(@collection.visibility).to eql('restricted')
      expect(@object.visibility).to eql('public')
    end
  end
end
