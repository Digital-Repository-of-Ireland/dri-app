describe DoiController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    stub_const(
        'DoiConfig',
        OpenStruct.new(
          { :username => "user",
            :password => "password",
            :prefix => '10.5072',
            :base_url => "http://repository.dri.ie",
            :publisher => "Digital Repository of Ireland" }
            )
        )
    Settings.doi.enable = true
  end

  after(:each) do
    Settings.doi.enable = false
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  before(:each) do
    @login_user = FactoryBot.create(:admin)
    sign_in @login_user

    @object = FactoryBot.create(:sound)
    @object.status = 'published'
    @object.save
  end

  describe "GET show" do
  
    it "assigns @history" do
      doi = DataciteDoi.create(object_id: @object.id)

      get :show, object_id: @object.id, id: doi.doi.split("#{DoiConfig.prefix}/DRI.")[1]
      expect(assigns(:history)).to eq([doi])      
    end

    it "alerts if doi is not the latest" do
      initial_doi = DataciteDoi.create(object_id: @object.id)
      updated_doi = DataciteDoi.create(object_id: @object.id, modified: 'test update')

      get :show, object_id: @object.id, id: initial_doi.doi.split("#{DoiConfig.prefix}/DRI.")[1]
      expect(flash[:notice]).to be_present
    end

    it "redirects if DOI is current" do
      initial_doi = DataciteDoi.create(object_id: @object.id)
      updated_doi = DataciteDoi.create(object_id: @object.id, modified: 'test update')

      get :show, object_id: @object.id, id: updated_doi.doi.split("#{DoiConfig.prefix}/DRI.")[1]
      expect(response).to redirect_to(catalog_path(@object.id))
    end

    it "updates doi" do
      @collection = DRI::Batch.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:creator] = [@login_user.email]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:resource_type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection[:status] = "published"
      @collection.save
      DataciteDoi.create(object_id: @collection.id)

      expect(DRI.queue).to receive(:push).with(an_instance_of(MintDoiJob)).once
      put :update, object_id: @collection.id, modified: 'objects added'

      DataciteDoi.where(object_id: @collection.id).first.delete
      @collection.delete
    end

    it "returns 404 for unknown DOI" do
      doi = DataciteDoi.create(object_id: @object.id)

      get :show, object_id: @object.id, id: 'aaa-9'
      expect(response.status).to eq(404)
    end

  end

end
