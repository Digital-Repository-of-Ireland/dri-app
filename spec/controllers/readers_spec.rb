require 'rails_helper'

describe ReadersController do
  include Devise::Test::ControllerHelpers

  before(:all) do
    @manager_user = FactoryBot.create(:collection_manager)
    @login_user = FactoryBot.create(:user)

    @collection = FactoryBot.create(:collection)
    @collection.manager_users_string = @manager_user.email
    @collection.save
    @collection.reload

    @group = UserGroup::Group.new(name: @collection.id,
      description: "Default Reader group for collection #{@collection.id}")
    @group.reader_group = true
    @group.save

    @collection.read_groups_string = "#{@collection.id}"
    @collection.save

    @object = FactoryBot.create(:sound)
    @collection.governed_items << @object
    @collection.save
  end

  after(:all) do
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

      @subcollection = FactoryBot.create(:collection)
      @subcollection.manager_users_string = @manager_user.email
      @subcollection.save

      @subobject = FactoryBot.create(:sound)

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

      expect(@login_user.member?(subgroup.id)).to be_falsey
      expect(@login_user.pending_member?(subgroup.id)).not_to be true

      expect {
        post :create, { id: @subcollection.id }
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
      group = UserGroup::Group.find_by(name: @collection.id)


      membership = @login_user.join_group(group.id)
      post :update, { id: @collection.id, user_id: @login_user.id }

      membership.reload
      expect(membership.approved?).to be true
    end
  end

  describe 'DELETE read request' do
    it "approves a pending membership" do
      sign_in @manager_user
      @request.env['HTTP_REFERER'] = "/catalog/#{@object.id}"
      group = UserGroup::Group.find_by(name: @collection.id)

      membership = @login_user.join_group(group.id)
      membership.approve_membership(@manager_user.id)
      membership.save

      expect {
        delete :destroy, { id: @collection.id, user_id: @login_user.id }
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(UserGroup::Membership.find_by(group_id: group.id, user_id: @login_user.id)).to be nil
    end
  end

end
