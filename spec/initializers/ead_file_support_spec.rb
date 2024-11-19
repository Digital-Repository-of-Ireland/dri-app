require 'rails_helper'

describe 'EadFileSupport' do

  let(:tmp_assets_dir) { Dir.mktmpdir }
  let(:login_user) { FactoryBot.create(:admin) }

  before(:each) do
    Settings.dri.files = tmp_assets_dir
  end

  after(:each) do
    login_user.delete
    FileUtils.remove_dir(tmp_assets_dir, force: true)
  end

  it 'should add an asset' do
    component = DRI::EadComponent.new
    component.identifier = ['IE/NIVAL KDW']
    component.identifier_id = 'KDW'
    component.country_code = 'IE'
    component.repository_code = 'IE-DuNIV'

    attributes_hash = {
        title: ['The test title'],
        creator: { display: ['Creator 1', 'Creator no role'], role: ['institution', ''], tag: ['persname', 'name'] },
        contributor: ['Contributor 1'],
        desc_scope_content: ['This is a test description for the object.'],
        desc_abstract: ['This is a test abstract for the object.'],
        desc_biog_hist: ['This is a test biographical history for the object.'],
        rights: ['This is a statement about the rights associated with this object'],
        type: ['Collection'],
        published_date: { display: ['2015'], normal: ['20150101'] },
        creation_date: { display: ['2000-2010'], normal: ['20000101/20101231'] },
        name_coverage: { display: ['Designer 1', 'Photographer 1'], role: ['designer', 'photographer'], tag: ['persname', 'corpname'] },
        geogname_coverage_access: { type: ['', 'dcterms:Point', 'logainm'], display: ['Dublin', 'name=Dublin; east=-6.266155; north=53.350140;', 'http://example.org/1234'] },
        temporal_coverage: { normal: ['2005'], datechar: ['coverage'], display: ['c. 2005'] },
        subject: ['Ireland', 'something else'],
        name_subject: ['subject name'],
        persname_subject: ['subject persname'],
        corpname_subject: ['subject corpname'],
        geogname_subject: ['subject geogname'],
        famname_subject: ['subject famname'],
        publisher: ['Publisher 1'],
        related_material: ['http://example.org/relmat'],
        alternative_form: ['http://example.org/altform'],
        language: { langcode: ['eng'], text: ['English'] },
        format: ['395 files']
    }
    component.depositor = login_user.email
    component.attributes = attributes_hash
    component.ead_level = 'otherlevel'
    component.ead_level_other = 'Item'
    component.object_version = 1
    component.save

    preservation = Preservation::Preservator.new(component)
    preservation.preserve(['descMetadata'])

    expect(component.add_file_to_object(File.new(File.join(fixture_paths, "SAMPLEA.mp3")), 'SAMPLEA.mp3')).to be true
    expect(component.object_version).to eq 2
    component.reload
    expect(component.generic_files.length).to eq 1

    component.destroy
  end

end
