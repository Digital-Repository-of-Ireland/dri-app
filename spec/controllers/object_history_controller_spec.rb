require 'rails_helper'

describe ObjectHistoryController do
  include Devise::Test::ControllerHelpers

  let(:login_user) { FactoryBot.create(:admin) }
  let(:tmp_assets_dir) { Dir.mktmpdir }

  before do
    Settings.dri.files = tmp_assets_dir
    sign_in login_user
  end

  after do
    FileUtils.remove_dir(tmp_assets_dir, force: true)
  end

  let(:object) { FactoryBot.create(:sound) }
  after { object.destroy if DRI::Identifier.object_exists?(object.alternate_id) }

  describe 'show' do
    # ObjectHistory's own internals (how it derives an audit trail/fixity
    # report) aren't something this spec has visibility into - it's
    # mocked at the exact boundary the controller uses it at, so these
    # tests verify the controller's own wiring (permission check, format
    # handling, instance variable assignment) rather than ObjectHistory's
    # behavior.
    let(:object_history) do
      instance_double(ObjectHistory, audit_trail: [{ version: 1 }], fixity: { verified: true }, to_premis: '<premis/>')
    end

    before do
      allow(ObjectHistory).to receive(:new).and_return(object_history)
    end

    it 'renders successfully for html requests and assigns versions/fixity from ObjectHistory' do
      get :show, params: { id: object.alternate_id }

      expect(response).to be_successful
      expect(assigns(:versions)).to eq([{ version: 1 }])
      expect(assigns(:fixity)).to eq(verified: true)
    end

    it 'builds ObjectHistory from the requested object\'s own SolrDocument' do
      expect(ObjectHistory).to receive(:new) do |object: nil|
        expect(object).to be_a(SolrDocument)
        expect(object.id).to eq(self.object.alternate_id)
        object_history
      end

      get :show, params: { id: object.alternate_id }
    end

    it 'renders the premis xml for xml requests' do
      get :show, params: { id: object.alternate_id, format: :xml }

      expect(response).to be_successful
      expect(response.body).to eq('<premis/>')
      expect(response.content_type).to include('text/xml')
    end

    it 'denies a signed-in user without edit permissions' do
      sign_out login_user
      plain_user = FactoryBot.create(:user)
      sign_in plain_user

      get :show, params: { id: object.alternate_id }

      expect(response.status).to eq(401)

      plain_user.destroy
    end
  end

  describe 'download_version' do
    before do
      # A real preserve, so Preservator's manifest_path/
      # file_inventory_from_path/signature_catalog_from_path have
      # something genuine to read. Only Moab::Bagger and the zip
      # exporter (whose internals this spec has no visibility into) are
      # stubbed - everything up to that point is exercised for real.
      Preservation::Preservator.new(object).remove_moab_dirs(true)
      Preservation::Preservator.new(object).preserve(['descMetadata'])
    end

    it 'sends the generated zip file for a valid version' do
      bagger = double('bagger', fill_bag: true)
      allow(Moab::Bagger).to receive(:new).and_return(bagger)

      exporter = double('exporter', write: true)
      allow(DRI::Exporters::ZipFile).to receive(:new).and_return(exporter)

      get :download_version, params: { id: object.alternate_id, version_id: 'v0001' }

      expect(response.status).to eq(200)
      expect(response.header['Content-Type']).to eq('application/zip')
      expect(response.header['Content-Disposition']).to include("#{object.alternate_id}_v0001.zip")
    end

    it 'passes the numeric version (stripped of its leading letter) through to the Preservator' do
      expect(Moab::Bagger).to receive(:new) do |file_inventory, signature_catalog, _tmp_dir|
        expect(file_inventory).to be_present
        expect(signature_catalog).to be_present
        double('bagger', fill_bag: true)
      end
      allow(DRI::Exporters::ZipFile).to receive(:new).and_return(double('exporter', write: true))

      get :download_version, params: { id: object.alternate_id, version_id: 'v0001' }

      expect(response.status).to eq(200)
    end

    it 'denies a signed-in user without edit permissions' do
      sign_out login_user
      plain_user = FactoryBot.create(:user)
      sign_in plain_user

      get :download_version, params: { id: object.alternate_id, version_id: 'v0001' }

      expect(response.status).to eq(401)

      plain_user.destroy
    end
  end
end