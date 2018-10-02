describe ReadersController do
  include Devise::Test::ControllerHelpers
  
  before(:each) do
    @manager_user = FactoryBot.create(:collection_manager)
    @login_user = FactoryBot.create(:user)
    
    @collection = DRI::Batch.with_standard :qdc
    @collection[:title] = ["A collection"]
    @collection[:description] = ["This is a Collection"]
    @collection[:rights] = ["This is a statement about the rights associated with this object"]
    @collection[:publisher] = ["RnaG"]
    @collection[:creator] = ["Creator"]
    @collection[:resource_type] = ["Collection"]
    @collection[:creation_date] = ["1916-01-01"]
    @collection[:published_date] = ["1916-04-01"]
    @collection.manager_users_string = @manager_user.email
    @collection.save

    @group = UserGroup::Group.new(name: @collection.id, 
      description: "Default Reader group for collection #{@collection.id}")
    @group.reader_group = true
    @group.save
    
    @collection.read_groups_string = "#{@collection.id}"
    @collection.save

    @object = DRI::Batch.with_standard :qdc
    @object[:title] = ["An Audio Title"]
    @object[:rights] = ["This is a statement about the rights associated with this object"]
    @object[:role_hst] = ["Collins, Michael"]
    @object[:contributor] = ["DeValera, Eamonn", "Connolly, James"]
    @object[:language] = ["ga"]
    @object[:description] = ["This is an Audio file"]
    @object[:published_date] = ["1916-04-01"]
    @object[:creation_date] = ["1916-01-01"]
    @object[:source] = ["CD nnn nuig"]
    @object[:geographical_coverage] = ["Dublin"]
    @object[:temporal_coverage] = ["1900s"]
    @object[:subject] = ["Ireland","something else"]
    @object[:resource_type] = ["Sound"]
    @object.save

    @collection.governed_items << @object
  end

  after(:each) do
    @login_user.delete
    @manager_user.delete

    @collection.delete
    @group.delete
  end

  describe 'POST read request' do
    it "creates a new pending membership" do
      sign_in @login_user

      @request.env['HTTP_REFERER'] = "/catalog/#{@object.id}"

      group = UserGroup::Group.find_by(name: @collection.id)
      expect(@login_user.member?(group.id)).to be_falsey
      expect(@login_user.pending_member?(group.id)).not_to be true

      expect {
        post :create, { :id => @collection.id }
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
      @login_user.reload
      expect(@login_user.pending_member?(group.id)).to be true
    end
  end

   describe 'POST read request for subcollection' do

    before(:each) do
      sign_in @login_user
     
      @subcollection = DRI::Batch.with_standard :qdc
      @subcollection[:title] = ["A collection"]
      @subcollection[:description] = ["This is a Collection"]
      @subcollection[:rights] = ["This is a statement about the rights associated with this object"]
      @subcollection[:publisher] = ["RnaG"]
      @subcollection[:creator] = ["Creator"]
      @subcollection[:resource_type] = ["Collection"]
      @subcollection[:creation_date] = ["1916-01-01"]
      @subcollection[:published_date] = ["1916-04-01"]
      @subcollection.manager_users_string = @manager_user.email
      @subcollection.save
            
      @subobject = DRI::Batch.with_standard :qdc
      @subobject[:title] = ["An Audio Title in the Sub Collection"]
      @subobject[:rights] = ["This is a statement about the rights associated with this object"]
      @subobject[:role_hst] = ["Collins, Michael"]
      @subobject[:contributor] = ["DeValera, Eamonn", "Connolly, James"]
      @subobject[:language] = ["ga"]
      @subobject[:description] = ["This is an Audio file"]
      @subobject[:published_date] = ["1916-04-01"]
      @subobject[:creation_date] = ["1916-01-01"]
      @subobject[:source] = ["CD nnn nuig"]
      @subobject[:geographical_coverage] = ["Dublin"]
      @subobject[:temporal_coverage] = ["1900s"]
      @subobject[:subject] = ["Ireland","something else"]
      @subobject[:resource_type] = ["Sound"]
      @subobject.save

      @subcollection.governed_items << @subobject
      @subcollection.governing_collection = @collection
      @subcollection.save
    end

    after(:each) do
      @subcollection.delete
    end  

    it "creates a new pending membership in the governing read group" do
      @request.env['HTTP_REFERER'] = "/catalog/#{@object.id}"

      group = UserGroup::Group.find_by(name: @collection.id)
      expect(@login_user.member?(group.id)).to be_falsey
      expect(@login_user.pending_member?(group.id)).not_to be true

      expect {
        post :create, { :id => @subcollection.id }
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
      @login_user.reload
      expect(@login_user.pending_member?(group.id)).to be true
    end

    it "creates a new pending membership in the subcollection read group" do
      subgroup = UserGroup::Group.new(name: @subcollection.id, 
      description: "Default Reader group for collection #{@subcollection.id}")
      subgroup.reader_group = true
      subgroup.save

      @subcollection.read_groups_string = "#{@subcollection.id}"
      @subcollection.save

      @request.env['HTTP_REFERER'] = "/catalog/#{@object.id}"

      group = UserGroup::Group.find_by(name: @subcollection.id)
      expect(@login_user.member?(group.id)).to be_falsey
      expect(@login_user.pending_member?(group.id)).not_to be true

      expect {
        post :create, { :id => @subcollection.id }
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      @login_user.reload
      expect(@login_user.pending_member?(subgroup.id)).to be true
      expect(@login_user.pending_member?(@group.id)).to be_falsey
    end
  end

  describe 'UPDATE read request' do
    it "approves a pending membership" do
      sign_in @manager_user
      @request.env['HTTP_REFERER'] = "/catalog/#{@object.id}"

      membership = @login_user.join_group(@group.id)

      post :update, { id: @collection.id, user_id: @login_user.id }

      membership.reload
      expect(membership.approved?).to be true
    end
  end

  describe 'DELETE read request' do
    it "approves a pending membership" do
      sign_in @manager_user
      @request.env['HTTP_REFERER'] = "/catalog/#{@object.id}"

      membership = @login_user.join_group(@group.id)
      membership.approve_membership(@manager_user.id)
      membership.save

      expect {
        delete :destroy, { id: @collection.id, user_id: @login_user.id }
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(UserGroup::Membership.find_by(group_id: @group.id, user_id: @login_user.id)).to be nil
    end
  end

end
