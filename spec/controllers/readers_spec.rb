require 'spec_helper'

describe ReadersController do
  include Devise::TestHelpers

  before(:each) do
    @manager_user = FactoryGirl.create(:collection_manager)
    @login_user = FactoryGirl.create(:user)
    
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

      expect(AuthMailer).to receive(:pending_mail).and_return(AuthMailer)
      expect(AuthMailer).to receive(:deliver_now)
      post :create, { :id => @collection.id }

      @login_user.reload
      expect(@login_user.pending_member?(group.id)).to be true
    end
  end

  describe 'UPDATE read request' do
    it "approves a pending membership" do
      sign_in @manager_user
      @request.env['HTTP_REFERER'] = "/catalog/#{@object.id}"

      membership = @login_user.join_group(@group.id)

      expect(AuthMailer).to receive(:approved_mail).and_return(AuthMailer)
      expect(AuthMailer).to receive(:deliver_now)
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

      expect(AuthMailer).to receive(:removed_mail).and_return(AuthMailer)
      expect(AuthMailer).to receive(:deliver_now)
      delete :destroy, { id: @collection.id, user_id: @login_user.id }

      expect(UserGroup::Membership.find_by(group_id: @group.id, user_id: @login_user.id)).to be nil
    end
  end

end