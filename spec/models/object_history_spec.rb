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

    @collection = FactoryBot.create(:collection)
    @collection[:status] = "public"
    @collection[:depositor] = "instmgr@dri.ie"
    @collection.edit_users = ['edituser@dri.ie', 'anotheruser@dri.ie']
    @collection.manager_users = ['manageruser@dri.ie']
    @collection.read_groups = ['test']
    @collection.save

    @object = FactoryBot.create(:sound)
    @object[:status] = "published"
    @object[:depositor] = "edituser@dri.ie"
    @object.save

    VersionCommitter.create(obj_id: @object.alternate_id, version_id: 'v0001', committer_login: "instmgr@dri.ie")

    @generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
    @generic_file.digital_object = @object
    @generic_file.apply_depositor_metadata(@user.email)
    @generic_file.save

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

  it 'should get versions' do
    versions = @object_history.audit_trail
    expect(versions.first[:version_id]).to eq 'v0001'
  end

  it 'should get asset information' do
    asset_info = @object_history.asset_info
    expect(asset_info.keys).to include(@generic_file.alternate_id)
  end

  it 'should call fixity check info for a collection' do
    history = ObjectHistory.new(object: @collection)
    expect(history).to receive(:fixity_check_collection)
    history.fixity
  end

  it 'should call fixity check info for a collection' do
    expect(@object_history).to receive(:fixity_check_object)
    @object_history.fixity
  end

  it 'should get collection fixity information' do
    report = FixityReport.create(collection_id: @collection.alternate_id)
    FixityCheck.create(fixity_report_id: report.id, collection_id: @collection.alternate_id, object_id: @object.alternate_id, verified: true)
    history = ObjectHistory.new(object: @collection)
    fixity = history.fixity_check_collection
    expect(fixity[:verified]).to eq('passed')
  end

  it 'should get collection fixity information with failures' do
    report = FixityReport.create(collection_id: @collection.alternate_id)
    FixityCheck.create(fixity_report_id: report.id, collection_id: @collection.alternate_id, object_id: @object.alternate_id, verified: false)
    history = ObjectHistory.new(object: @collection)
    fixity = history.fixity_check_collection
    expect(fixity[:verified]).to eq('failed')
    expect(fixity[:result]).to include(@object.alternate_id)
  end

  it 'should get object fixity information' do
    report = FixityReport.create(collection_id: @collection.alternate_id)
    FixityCheck.create(fixity_report_id: report.id, collection_id: @collection.alternate_id, object_id: @object.alternate_id, verified: true, result: 'test')
    fixity = @object_history.fixity_check_object
    expect(fixity[:verified]).to eq('passed')
    expect(fixity[:result]).to eq('test')
  end
end
