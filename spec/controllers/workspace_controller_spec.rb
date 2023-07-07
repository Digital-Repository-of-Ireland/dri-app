require 'rails_helper'

describe WorkspaceController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @manager_user = FactoryBot.create(:collection_manager)
    @login_user = FactoryBot.create(:user)

    @collection = FactoryBot.create(:collection)
    @collection.manager_users_string = @manager_user.email
    @collection.read_groups_string = "#{@collection.alternate_id}"
    @collection.save

    @edit_collection = FactoryBot.create(:collection)
    @edit_collection.edit_users_string = @manager_user.email
    @edit_collection.read_groups_string = "#{@collection.alternate_id}"
    @edit_collection.save

    @group = UserGroup::Group.new(name: @collection.alternate_id,
      description: "Default Reader group for collection #{@collection.alternate_id}")
    @group.reader_group = true
    @group.save

    @object = FactoryBot.create(:sound)
    @collection.governed_items << @object
    @collection.save
  end

  describe 'GET index request' do
    it "counts the collection types" do
      sign_in @manager_user

      @request.env['HTTP_REFERER'] = "/workspace"

      get :index
      expect(assigns(:collection_count)).to eq 2
      expect(assigns(:manage_collections_count)).to eq 1
      expect(assigns(:edit_collections_count)).to eq 1
    end
  end

  describe 'GET collections request' do
    it "lists the users collection details" do
      sign_in @manager_user

      get :collections
      expect(assigns(:collection_data).size).to eq 2
      expect(assigns(:collection_data)[0][:permission]).to be_in(["manage", "edit"])
      expect(assigns(:collection_data)[1][:permission]).to be_in(["manage", "edit"])
    end
  end

  describe 'GET readers request' do
    it "list the collections reader groups" do
      sign_in @manager_user

      group = UserGroup::Group.find_by(name: @collection.alternate_id)
      membership = @login_user.join_group(group.id)
      membership.approve_membership(@manager_user.id)
      membership.save

      get :readers
      expect(assigns(:read_group_memberships).size).to eq 1
      expect(assigns(:read_group_memberships)[0][:collection].id).to eq @collection.alternate_id
      expect(assigns(:read_group_memberships)[0][:approved].size).to eq 1
    end
  end
end
