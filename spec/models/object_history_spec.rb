require 'rails_helper'

describe ObjectHistory  do
  
  before do
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


  it 'should get the root collection depositor as institute mgr' do
    @object_history.institute_manager.should == 'instmgr@dri.ie'
  end

  it 'should get the collection edit user' do
    @object_history.governing_attribute('edit_users_string').should == "edituser@dri.ie, anotheruser@dri.ie"
  end

  it 'should get the collection manager user' do
    @object_history.governing_attribute('manager_users_string').should == "manageruser@dri.ie"
  end

  it 'should get the collection read groups' do
    @object_history.governing_attribute('read_groups_string').should == "test"
  end

  it 'should get the collection read users via groups' do
    @object_history.read_users_by_group.should == [['fname','sname','user@dri.ie']]
  end

end
