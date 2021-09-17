require 'rails_helper'

describe ReadersController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @manager_user = FactoryBot.create(:collection_manager)
    @login_user = FactoryBot.create(:user)

    @collection = FactoryBot.create(:collection)
    @collection.manager_users_string = @manager_user.email
    @collection.save
    @collection.reload

    @group = UserGroup::Group.new(name: @collection.alternate_id,
      description: "Default Reader group for collection #{@collection.alternate_id}")
    @group.reader_group = true
    @group.save

    @collection.read_groups_string = "#{@collection.alternate_id}"
    @collection.save

    @object = FactoryBot.create(:sound)

    @collection.governed_items << @object
    @collection.save
  end

  after(:each) do
    @login_user.delete
    @manager_user.delete

    @collection.destroy
    @group.delete
  end

  describe 'POST read request' do
    it "creates a new pending membership" do
      sign_in @login_user

      @request.env['HTTP_REFERER'] = "/catalog/#{@object.alternate_id}"

      group = UserGroup::Group.find_by(name: @collection.alternate_id)
      expect(@login_user.member?(group.id)).to be_falsey
      expect(@login_user.pending_member?(group.id)).not_to be true

      expect {
        post :create, params: { id: @collection.alternate_id }
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
      @subcollection.destroy
    end

    it "creates a new pending membership in the governing read group" do
      @request.env['HTTP_REFERER'] = "/catalog/#{@object.alternate_id}"

      group = UserGroup::Group.find_by(name: @collection.alternate_id)
      expect(@login_user.member?(group.id)).to be_falsey
      expect(@login_user.pending_member?(group.id)).not_to be true

      expect {
        post :create, params: { id: @subcollection.alternate_id }
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
      @login_user.reload
      expect(@login_user.pending_member?(group.id)).to be true
    end

    it "creates a new pending membership in the subcollection read group" do
      subgroup = UserGroup::Group.new(name: @subcollection.alternate_id,
      description: "Default Reader group for collection #{@subcollection.alternate_id}")
      subgroup.reader_group = true
      subgroup.save
      subgroup.reload

      @subcollection.read_groups_string = "#{@subcollection.alternate_id}"
      @subcollection.save

      @request.env['HTTP_REFERER'] = "/catalog/#{@object.alternate_id}"

      expect(@login_user.member?(subgroup.id)).to be_falsey
      expect(@login_user.pending_member?(subgroup.id)).not_to be true

      expect {
        post :create, params: { id: @subcollection.alternate_id }
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      @login_user.reload
      expect(@login_user.pending_member?(subgroup.id)).to be true
      expect(@login_user.pending_member?(@group.id)).to be_falsey
    end
  end

  describe 'UPDATE read request' do
    it "approves a pending membership" do
      sign_in @manager_user
      @request.env['HTTP_REFERER'] = "/catalog/#{@object.alternate_id}"
      group = UserGroup::Group.find_by(name: @collection.alternate_id)

      membership = @login_user.join_group(group.id)
      post :update, params: { id: @collection.alternate_id, user_id: @login_user.id }

      membership.reload
      expect(membership.approved?).to be true
    end
  end

  describe 'DELETE read request' do
    it "approves a pending membership" do
      sign_in @manager_user
      @request.env['HTTP_REFERER'] = "/catalog/#{@object.alternate_id}"
      group = UserGroup::Group.find_by(name: @collection.alternate_id)

      membership = @login_user.join_group(group.id)
      membership.approve_membership(@manager_user.id)
      membership.save

      expect {
        delete :destroy, params: { id: @collection.alternate_id, user_id: @login_user.id }
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(UserGroup::Membership.find_by(group_id: group.id, user_id: @login_user.id)).to be nil
    end
  end

end
