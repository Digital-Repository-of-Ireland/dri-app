require 'rails_helper'

describe ObjectHistory  do
  
  before do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @user_email = "user@dri.ie"
    @user_fname = "fname"
    @user_sname = "sname"
    @user_locale = "en"
    @user_password = "password"
    @user = User.create(
      email: @user_email,
      password: @user_password,
      password_confirmation: @user_password,
      locale: @user_locale,
      first_name: @user_fname,
      second_name: @user_sname
    )

    @group = Group.create(name: "test", description: "test group")
    @membership = @user.join_group(@group.id)
    @membership.approved_by = @user.id
    @membership.save

    @collection = FactoryGirl.create(:collection)
    @collection[:status] = "public"
    @collection[:depositor] = "instmgr@dri.ie"
    @collection.edit_users = ['edituser@dri.ie', 'anotheruser@dri.ie']
    @collection.manager_users = ['manageruser@dri.ie']
    @collection.read_groups = ['test']
    @collection.save

    @object = FactoryGirl.create(:sound)
    @object[:status] = "published"
    @object[:depositor] = "edituser@dri.ie"
    @object.save

    @collection.governed_items << @object
    @collection.save

    @object_history = ObjectHistory.new(object: @object)
  end

  after do
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  it 'should get the root collection depositor as institute mgr' do
    expect(@object_history.institute_manager).to be == 'instmgr@dri.ie'
  end

  it 'should get the collection edit user' do
    expect(@object_history.governing_attribute('edit_users_string')).to be == "edituser@dri.ie, anotheruser@dri.ie"
  end

  it 'should get the collection manager user' do
    expect(@object_history.governing_attribute('manager_users_string')).to be == "manageruser@dri.ie"
  end

  it 'should get the collection read groups' do
    expect(@object_history.governing_attribute('read_groups_string')).to be == "test"
  end

  it 'should get the collection read users via groups' do
    expect(@object_history.read_users_by_group).to be == [['fname','sname','user@dri.ie']]
  end

end
