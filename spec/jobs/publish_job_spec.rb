require 'rails_helper'
require 'solr/query'

# declare an exclusion filter
RSpec.configure { |c| c.filter_run_excluding(slow: true) }

describe 'PublishJob' do

  before do
    allow_any_instance_of(PublishJob).to receive(:completed)
    allow_any_instance_of(PublishJob).to receive(:set_status)
    allow_any_instance_of(PublishJob).to receive(:at)
  end

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:collection_manager)

    @collection = FactoryBot.create(:collection)
    @collection[:status] = "draft"
    @collection.save

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
    it "should set a collection\'s reviewed objects status to published" do
      allow(Resque).to receive(:enqueue)
      job = PublishJob.new('test', { 'collection_id' => @collection.alternate_id, 'user_id' => @login_user.id })
      job.perform

      @collection.reload
      @object.reload

      expect(@collection.status).to eql('published')
      expect(@object.status).to eql('published')
    end

    it 'should set published_at' do
      allow(Resque).to receive(:enqueue)
      job = PublishJob.new('test', { 'collection_id' => @collection.alternate_id, 'user_id' => @login_user.id })
      job.perform

      @collection.reload
      @object.reload

      expect(@collection.status).to eql('published')
      expect(@object.status).to eql('published')

      expect(@collection.published_at).to_not be nil
      expect(@object.published_at).to_not be nil
    end

    it 'should not set an object to published if within an unreviewed sub-collection' do
      @reviewed = FactoryBot.create(:collection)
      @reviewed[:status] = 'reviewed'
      @reviewed.save

      @subcollection = FactoryBot.create(:collection)
      @subcollection[:status] = 'draft'
      @subcollection.governed_items << @reviewed
      @subcollection.save

      @collection.governed_items << @subcollection
      @collection.save

      allow(Resque).to receive(:enqueue)
      job = PublishJob.new('test', { 'collection_id' => @collection.alternate_id, 'user_id' => @login_user.id })
      job.perform

      @collection.reload
      @subcollection.reload
      @reviewed.reload

      expect(@collection.status).to eq('published')
      expect(@subcollection.status).to eq('draft')
      expect(@reviewed.status).to eq('reviewed')
    end

    it "should not set a collection\'s draft objects to published" do
      @draft = FactoryBot.create(:sound)
      @draft[:status] = 'draft'
      @draft.save

      @collection.governed_items << @draft
      @collection.save

      job = PublishJob.new('test', { 'collection_id' => @collection.alternate_id, 'user_id' => @login_user.id })
      job.perform

      @collection.reload
      @draft.reload

      expect(@draft.status).to eq('draft')

      @draft.delete
    end

    it 'should queue a doi job when publishing an object' do
        stub_const("DoiConfig", OpenStruct.new(
        username: 'user',
        password: 'password',
        prefix: '10.5072',
        base_url: 'http://www.dri.ie/repository',
        publisher: 'Digital Repository of Ireland'))
      Settings.doi.enable = true

      job = PublishJob.new('test', { 'collection_id' => @collection.alternate_id, 'user_id' => @login_user.id })

      expect(Resque).to receive(:enqueue).twice
      job.perform

      @collection.reload
      @object.reload

      expect(@collection.status).to eq('published')
      expect(@object.status).to eq('published')

      Settings.doi.enable = false
    end

    @slow
    it 'should handle more than 10 objects', slow: true do
      20.times do
        o = FactoryBot.create(:sound)
        o[:status] = 'reviewed'
        o.save

        @collection.governed_items << o
      end

      @collection.save

      job = PublishJob.new('test', { 'collection_id' => @collection.alternate_id, 'user_id' => @login_user.id })
      job.perform

      q = "collection_id_sim:\"#{@collection.alternate_id}\" AND status_ssi:published"
      expect(SolrQuery.new(q).count).to eq(21)
    end
  end
end
