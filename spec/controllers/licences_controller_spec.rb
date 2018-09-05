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

  describe "create" do

    it "should create a new licence" do
      @admin_user = FactoryBot.create(:admin)
      sign_in @admin_user
     
      expect {
        post :create, licence: { name: 'A Test Licence', description: 'This is a test licence' }
      }.to change(Licence, :count).by(1)
    end
  end

  describe "update" do

    it "should update a licence" do
      @admin_user = FactoryBot.create(:admin)
      sign_in @admin_user
     
      licence = Licence.create(name: 'Test Update Licence', description: 'Test description')
      put :update, id: licence.id, licence: { name: 'A Test Licence', description: 'Modified description' }

      licence.reload
      expect(licence.description).to eq('Modified description')
    end

    it "should ignore non-uri logo and url" do
      @admin_user = FactoryBot.create(:admin)
      sign_in @admin_user
     
      licence = Licence.create(name: 'Test Update Licence', description: 'Test description')
      put :update, id: licence.id, licence: { name: 'A Test Licence', description: 'Modified description', url: 'test url', logo: 'test logo' }

      licence.reload
      expect(licence.description).to eq('Modified description')
      expect(licence.logo).to be nil
      expect(licence.url).to be nil
    end

    it "should accept valid uri logo and url" do
      @admin_user = FactoryBot.create(:admin)
      sign_in @admin_user
     
      licence = Licence.create(name: 'Test Update Licence', description: 'Test description')
      put :update, id: licence.id, licence: { name: 'A Test Licence', description: 'Modified description', url: 'http://test.licence', logo: 'http://test.licence/logo' }

      licence.reload
      expect(licence.description).to eq('Modified description')
      expect(licence.logo).to eq('http://test.licence/logo')
      expect(licence.url).to eq('http://test.licence')
    end
  end
end
