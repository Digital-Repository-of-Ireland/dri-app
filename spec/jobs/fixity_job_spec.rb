require 'rails_helper'
require 'solr/query'

describe 'FixityJob' do
  
  before do
    allow_any_instance_of(FixityJob).to receive(:completed)
    allow_any_instance_of(FixityJob).to receive(:set_status)
    allow_any_instance_of(FixityJob).to receive(:at)
  end

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryGirl.create(:collection_manager)

    @collection = FactoryGirl.create(:collection)
    @collection.save

    @object = FactoryGirl.create(:sound)
    @object.save

    @collection.governed_items << @object
    @collection.save
  end

  after(:each) do
    @object.delete
    @collection.delete
   
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'run' do
    it "should set create a FixityCheck for a collection\'s objects" do
      job = FixityJob.new('test', { 'collection_id' => @collection.id, 'user_id' => @login_user.id })
      
      expect{ job.perform }.to change(FixityCheck, :count).by(1)
      expect(FixityCheck.find_by(object_id: @object.id).verified).to be true
    end
  end
end
