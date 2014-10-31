require 'spec_helper'
require 'inheritance_methods'

describe "inheritance" do
  include InheritanceMethods

  before do
    @user_email = "user@dri.ie"
    @user_fname = "fname"
    @user_sname = "sname"
    @user_locale = "en"
    @user_password = "password"
    @user = User.create(:email => @user_email, :password => @user_password, :password_confirmation => @user_password, :locale => @user_locale, :first_name => @user_fname, :second_name => @user_sname)

    @group = Group.create(name: "test group", description: "test group")
    @membership = @user.join_group(@group.id)
    @membership.approved_by = @user.id
    @membership.save

    @collection = Batch.with_standard :qdc
    @collection[:title] = ["A collection"]
    @collection[:description] = ["This is a Collection"]
    @collection[:rights] = ["This is a statement about the rights associated with this object"]
    @collection[:publisher] = ["Rspec"]
    @collection[:type] = ["Collection"]
    @collection[:creation_date] = ["1916-01-01"]
    @collection[:published_date] = ["1916-04-01"]
    @collection[:status] = ["public"]
    @collection[:depositor] = "instmgr@dri.ie"
    @collection.edit_users = ["edituser@dri.ie", "anotheruser@dri.ie"]
    @collection.manager_users = ["manageruser@dri.ie"]
    @collection.read_groups = ["test group"]
    @collection.save

    @object = Batch.with_standard :qdc
    @object[:title] = ["An Audio Title"]
    @object[:rights] = ["This is a statement about the rights associated with this object"]
    @object[:role_hst] = ["Collins, Michael"]
    @object[:language] = ["ga"]
    @object[:description] = ["This is an Audio file"]
    @object[:published_date] = ["1916-04-01"]
    @object[:creation_date] = ["1916-01-01"]
    @object[:subject] = ["rspec", "inheritance"]
    @object[:type] = ["Sound"]
    @object[:status] = ["published"]
    @object[:depositor] = "edituser@dri.ie"
    @object.save

    @collection.governed_items << @object
  end


  it 'should get the root collection depositor as institute mgr' do
    get_institute_manager(@object).should == 'instmgr@dri.ie'
  end

  it 'should get the collection edit user' do
    get_governing_attribute(@object, 'edit_users_string').should == "edituser@dri.ie, anotheruser@dri.ie"
  end

  it 'should get the collection manager user' do
    get_governing_attribute(@object, 'manager_users_string').should == "manageruser@dri.ie"
  end

  it 'should get the collection read groups' do
    get_governing_attribute(@object, 'read_groups_string').should == "test group"
  end

  it 'should get the collection read users via groups' do
    get_read_users_via_group(@object).should == [['fname','sname','user@dri.ie']]
  end

end
