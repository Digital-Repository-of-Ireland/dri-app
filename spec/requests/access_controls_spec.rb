require 'rails_helper'

describe AccessControlsController, type: :request do

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:admin)
    sign_in @login_user

    @collection = FactoryBot.create(:collection)
    @collection.apply_depositor_metadata(@login_user.to_s)
    @collection.manager_users_string = @login_user.to_s
    @collection.read_groups_string = 'public'
    @collection.master_file_access = 'public'
    @collection.save
  end

  after(:each) do
    @collection.delete
    @login_user.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'update' do

    it 'should update valid permissions' do
      expect(Resque).to receive(:enqueue).once
      put "/objects/#{@collection.alternate_id}/access", params: { digital_object: { read_groups_string: @collection.alternate_id.to_s, manager_users_string: @login_user.to_s } }
      @collection.reload

      expect(@collection.read_groups_string).to eq(@collection.alternate_id.to_s)
    end

    it 'should not update with invalid permissions' do
      put "/objects/#{@collection.alternate_id}/access", params: { digital_object: { edit_users_string: '', manager_users_string: '' } }
      @collection.reload

      expect(@collection.manager_users_string).to eq(@login_user.to_s)
      expect(flash[:alert]).to be_present
    end

  end

  describe 'show' do

    let(:object1) { FactoryBot.create(:sound) }
    let(:object2) { FactoryBot.create(:sound) }

    it 'should create a csv' do
      object2.master_file_access = 'private'
      object2.save
      @collection.governed_items << object1
      @collection.governed_items << object2
      @collection.save

      get "/my_collections/#{@collection.alternate_id}/access.csv"
      expect(response.status).to eq(200)
      expect(response.header['Content-Type']).to eq('text/csv')

      csv = CSV.parse(response.body, headers: true)
      expect(csv[0][0]).to eql(@collection.title.first)
      expect(csv[0][1]).to eql(object1.title.first)
      expect(csv[0][2]).to eq 'public'
      expect(csv[0][3]).to eq 'surrogates and uploaded originals'

      expect(csv[1][0]).to eql(@collection.title.first)
      expect(csv[1][1]).to eql(object2.title.first)
      expect(csv[1][2]).to eq 'public'
      expect(csv[1][3]).to eq 'surrogates only'
    end

    it 'should include objects with inherit file and restricted read' do
      object2.master_file_access = 'inherit'
      object2.read_groups_string = object2.alternate_id
      object2.save
      @collection.governed_items << object1
      @collection.governed_items << object2
      @collection.save

      get "/my_collections/#{@collection.alternate_id}/access.csv"
      expect(response.status).to eq(200)
      expect(response.header['Content-Type']).to eq('text/csv')

      csv = CSV.parse(response.body, headers: true)
      expect(csv[0][0]).to eql(@collection.title.first)
      expect(csv[0][1]).to eql(object1.title.first)
      expect(csv[0][2]).to eq 'public'
      expect(csv[0][3]).to eq 'surrogates and uploaded originals'

      expect(csv[1][0]).to eql(@collection.title.first)
      expect(csv[1][1]).to eql(object2.title.first)
      expect(csv[1][2]).to eq 'restricted'
      expect(csv[1][3]).to eq 'surrogates and uploaded originals'
    end

    it 'should include objects in subcollections' do
      subcollection = FactoryBot.create(:collection)
      subcollection.title = 'subcollection'
      subcollection.governing_collection = @collection
      subcollection.save

      object3 = FactoryBot.create(:sound)
      object3.title = 'sub-collection object'
      object3.governing_collection = subcollection
      object3.save

      @collection.governed_items << object1
      @collection.governed_items << object2
      @collection.save

      get "/my_collections/#{@collection.alternate_id}/access.csv"

      csv = CSV.parse(response.body, headers: true)

      expect(csv[0][0]).to eql(@collection.title.first)
      expect(csv[0][1]).to eql(object1.title.first)
      expect(csv[0][2]).to eq 'public'
      expect(csv[0][3]).to eq 'surrogates and uploaded originals'

      expect(csv[1][0]).to eql(@collection.title.first)
      expect(csv[1][1]).to eql(object2.title.first)
      expect(csv[1][2]).to eq 'public'
      expect(csv[1][3]).to eq 'surrogates and uploaded originals'

      expect(csv[2][0]).to eql(subcollection.title.first)
      expect(csv[2][1]).to eql(object3.title.first)
      expect(csv[2][2]).to eq 'public'
      expect(csv[2][3]).to eq 'surrogates and uploaded originals'
    end
  end
end
