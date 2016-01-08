require "spec_helper"

describe LicencesController do
  include Devise::TestHelpers

  describe "permissions" do
  
    it 'should allow an administrator to create a licence' do
       @admin_user = FactoryGirl.create(:admin)
       sign_in @admin_user
 
       get :new            
       expect(response).to render_template('new')
    end

    it 'should not allow an ordinary user to create a licence' do
      @user = FactoryGirl.create(:user)
      sign_in @user

      get :new
      expect(response.status).to eq(401)
    end
  end

end
