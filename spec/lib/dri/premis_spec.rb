require 'rails_helper'

describe DRI::Premis do

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
    @object.doi = "10.7486/DRI.12345"
    @object.save

    VersionCommitter.create(obj_id: @object.alternate_id, version_id: 'v0001', committer_login: "instmgr@dri.ie")

    @generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
    @generic_file.digital_object = @object
    @generic_file.apply_depositor_metadata(@user.email)
    @generic_file.save

    @object.reload

    @collection.governed_items << @object
    @collection.save

    @object_history = ObjectHistory.new(object: SolrDocument.find(@object.alternate_id))
  end

  after do
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

   it 'should generate valid premis XML' do
    report = FixityReport.create(collection_id: @collection.alternate_id)
    FixityCheck.create(fixity_report_id: report.id, collection_id: @collection.alternate_id, object_id: @object.alternate_id, verified: true, result: 'test')
    fixity = @object_history.fixity_check_object
    doc = Nokogiri::XML(@object_history.to_premis)
    expect(MetadataValidator.schema_valid?(doc, 'xmlns:premis', 'http://www.loc.gov/premis/v3')[0]).to be true
  end
end
