require 'rails_helper'

describe LicencesController do
  include Devise::Test::ControllerHelpers

  describe "permissions" do
  
    it 'should allow an administrator to create a licence' do
       @admin_user = FactoryBot.create(:admin)
       sign_in @admin_user
 
       get :new            
       expect(response).to render_template('new')
    end

    it 'should not allow an ordinary user to create a licence' do
      @user = FactoryBot.create(:user)
      sign_in @user

      get :new
      expect(response.status).to eq(401)
    end
  end

end
