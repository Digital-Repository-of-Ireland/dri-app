describe SurrogatesController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:admin)
    sign_in @login_user

    @collection = FactoryBot.create(:collection)
    @object = FactoryBot.create(:sound)
    
    @collection.governed_items << @object    
    @collection.save
    
    @gf = DRI::GenericFile.new
    @gf.apply_depositor_metadata(@login_user)
    @gf.batch = @object
    @gf.save
  end

  after(:each) do
    @gf.delete
    @object.delete
    @collection.delete

    @login_user.delete
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'update' do

    it 'should update a collections surrogates' do
      request.env["HTTP_REFERER"] = "/"
      DRI.queue.should_receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, id: @collection.id
    end

    it 'should update an objects surrogates' do
      request.env["HTTP_REFERER"] = "/"
      DRI.queue.should_receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, id: @object.id
    end

    it 'should update multiple files' do
      @gf2 = DRI::GenericFile.new
      @gf2.apply_depositor_metadata(@login_user)
      @gf2.batch = @object
      @gf2.save
      
      request.env["HTTP_REFERER"] = "/"
      DRI.queue.should_receive(:push).with(an_instance_of(CharacterizeJob)).twice
      put :update, id: @object.id

      @gf2.delete
    end

  end
end
