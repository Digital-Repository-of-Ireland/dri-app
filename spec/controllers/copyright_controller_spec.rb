require 'rails_helper'

describe CopyrightsController do
  include Devise::Test::ControllerHelpers

  describe "permissions" do

    it 'should allow an administrator to create a copyright' do
       @admin_user = FactoryBot.create(:admin)
       sign_in @admin_user

       get :new
       expect(response).to render_template('new')
    end

    it 'should not allow an ordinary user to create a copyright' do
      @user = FactoryBot.create(:user)
      sign_in @user

      get :new
      expect(response.status).to eq(401)
    end
  end

  describe "create" do

    it "should create a new copyright" do
      @admin_user = FactoryBot.create(:admin)
      sign_in @admin_user

      expect {
        post :create, params: { copyright: { name: 'A Test Copyright', description: 'This is a test copyright' } }
      }.to change(Copyright, :count).by(1)
    end
  end

  describe "update" do

    it "should update a copyright" do
      @admin_user = FactoryBot.create(:admin)
      sign_in @admin_user

      copyright = Copyright.create(name: 'Test Update Copyright', description: 'Test description')
      put :update, params: { id: copyright.id, copyright: { name: 'A Test Copyright', description: 'Modified description' } }

      copyright.reload
      expect(copyright.description).to eq('Modified description')
    end

    it "should ignore non-uri logo and url" do
      @admin_user = FactoryBot.create(:admin)
      sign_in @admin_user

      copyright = Copyright.create(name: 'Test Update Copyright', description: 'Test description')
      put :update, params: { id: copyright.id, copyright: { name: 'A Test Copyright', description: 'Modified description', url: 'test url', logo: 'test logo' } }

      copyright.reload
      expect(copyright.description).to eq('Modified description')
      expect(copyright.logo).to be nil
      expect(copyright.url).to be nil
    end

    it "should accept valid uri logo and url" do
      @admin_user = FactoryBot.create(:admin)
      sign_in @admin_user

      copyright = Copyright.create(name: 'Test Update Copyright', description: 'Test description')
      put :update, params: { id: copyright.id, copyright: { name: 'A Test Copyright', description: 'Modified description', url: 'http://test.copyright', logo: 'http://test.copyright/logo' } }

      copyright.reload
      expect(copyright.description).to eq('Modified description')
      expect(copyright.logo).to eq('http://test.copyright/logo')
      expect(copyright.url).to eq('http://test.copyright')
    end
  end
end
