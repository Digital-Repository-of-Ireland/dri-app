require 'rails_helper'
require 'swagger_helper'

describe IiifController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
  end

  after(:each) do
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'GET show' do
    let(:collection) { FactoryBot.create(:collection) }
    let(:object) { FactoryBot.create(:image) }

    it "should allow access to public, published image" do
      collection.status = 'published'
      collection.save

      object.status = 'published'
      object.read_groups_string = 'public'
      object.governing_collection = collection
      object.save
      
      get :show, id: "#{object.id}:test", method: 'show'
      expect(response.status).to eq(200)
    end

    it "should allow info request for published image" do
      collection.status = 'published'
      collection.save

      object.status = 'published'
      object.governing_collection = collection
      object.save
      
      get :show, id: "#{object.id}:test", method: 'info'
      expect(response.status).to eq(200)
    end

    it 'should not allow access to restricted images' do
      collection.status = 'published'
      collection.save

      object.status = 'published'
      object.read_groups_string = ''
      object.governing_collection = collection
      object.save
      
      get :show, id: "#{object.id}:test", method: 'show'
      expect(response.status).to eq(401)
    end
  end

  describe 'GET manifest' do
    let(:collection) { FactoryBot.create(:collection) }
    let(:object) { FactoryBot.create(:image) }
    let(:login_user) { FactoryBot.create(:admin) }
    before(:each) { sign_in login_user }

    it 'should return a valid manifest for an object' do
      get :manifest, id: object.id, format: :json
      expect { JSON.parse(response.body) }.not_to raise_error
    end

    it 'should return a valid collection manifest for a collection' do
      get :manifest, id: collection.id, format: :json
      expect { JSON.parse(response.body) }.not_to raise_error
    end
  end

  describe 'Get sequence', type: :requeset do
    let(:collection) { FactoryBot.create(:collection) }
    let(:object) { FactoryBot.create(:image) }
    let(:login_user) { FactoryBot.create(:admin) }
    before(:each) do
      sign_in login_user
      # collection.governed_items << object
      # collection.status = 'published'
      # collection.governed_items.map do |item|
      #   item.status = 'published'
      # end
    end

    it 'should return a valid manifest for a collection' do
      get :sequence, id: collection.id, format: :json
      expect { JSON.parse(response.body) }.not_to raise_error
    end

    include_context 'rswag_user_with_collections' do
      it 'should put all published images in the collection in a sequence' do
        require 'byebug'
        byebug
        sign_in @example_user
        get :sequence, id: collection.id, format: :json
        sequences = JSON.parse(response.body)['sequences']
        image_ids = sequences.map do |seq| 
          seq['canvases'].map do |canvas|
            canvas['images'].map do |image|
              image_url = image['resource']['service']['@id']
              # get id, between /images/ and :
              # e.g http://localhost:3000/images/j9602061v:zp38wc62h
              image_url[/\/images\/(.*)\:/m, 1]
            end
          end
        end.flatten
      end

    end 
  end
end
