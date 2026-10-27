# frozen_string_literal: true
require 'rails_helper'
require 'tmpdir'

RSpec.describe DRIBatchIngest::IngestController, type: :controller do
  include Devise::Test::ControllerHelpers
  include Warden::Test::Helpers

  let(:user) { FactoryBot.create(:collection_manager, email: 'ingest.user@example.com') }
  let(:other_user) { FactoryBot.create(:collection_manager, email: 'other.user@example.com') }
  let(:storage_root) { Dir.mktmpdir }
  let(:home) { DRIBatchIngest::UserStorage.home_for(user.email) }

  before do
    allow(Settings.ingest).to receive(:storage_root).and_return(storage_root)
    allow(Resque).to receive(:enqueue)
  end

  after { FileUtils.remove_entry(storage_root) }

  # --- helpers ---------------------------------------------------------------

  def assigned(name)
    controller.view_assigns[name.to_s]
  end

  def create_ingest(owner = user, created_at: Time.current)
    DRIBatchIngest::UserIngest.create!(user: owner, created_at: created_at)
  end

  def create_batch(ingest)
    DRIBatchIngest::IngestBatch.create!(
      user_ingest: ingest, collection_id: 'col1', email: ingest.user.email
    )
  end

  # One media object with one master file per status given.
  def create_media_object(batch, *statuses)
    media_object = DRIBatchIngest::MediaObject.create!(ingest_batch: batch, collection: 'col1')
    statuses.each do |status|
      DRIBatchIngest::MasterFile.create!(media_object: media_object, status_code: status)
    end
    media_object
  end

  def solr_doc(id, title, parents = nil)
    doc = double("solr doc #{id}", id: id)
    allow(doc).to receive(:[]).with('title_tesim').and_return([title])
    allow(doc).to receive(:[]).with('ancestor_id_ssim').and_return(parents)
    doc
  end

  context 'when signed out' do
    it 'redirects #new' do
      get :new
      expect(response).to have_http_status(:redirect)
    end

    it 'redirects #show' do
      get :show, params: { id: 1 }
      expect(response).to have_http_status(:redirect)
    end

    it 'does not create an ingest or enqueue anything on #create' do
      expect {
        post :create, params: { collection_id: 'col1', metadata_path: 'metadata' }
      }.not_to change(DRIBatchIngest::UserIngest, :count)

      expect(response).to have_http_status(:redirect)
      expect(Resque).not_to have_received(:enqueue)
    end

    it 'does not enqueue anything on #update' do
      batch = create_batch(create_ingest(other_user))

      put :update, params: { id: batch.id }

      expect(response).to have_http_status(:redirect)
      expect(Resque).not_to have_received(:enqueue)
    end
  end

  context 'when signed in' do
    before { sign_in user }

    describe 'GET #new' do
      let(:docs) { [] }
      let(:solr_args) { [] }

      before do
        query = double('Solr::Query')
        allow(query).to receive(:each) { |&block| docs.each(&block) }
        allow(Solr::Query).to receive(:new) do |*args|
          solr_args.replace(args)
          query
        end
      end

      it 'renders successfully' do
        get :new
        expect(response).to have_http_status(:ok)
      end

      describe 'ingests' do
        it "assigns only the current user's ingests, newest first" do
          older = create_ingest(created_at: 2.days.ago)
          newer = create_ingest(created_at: 1.day.ago)
          create_ingest(other_user)

          get :new

          expect(assigned(:ingests).map(&:id)).to eq([newer.id, older.id])
        end

        it 'shows five ingests per page' do
          6.times { |i| create_ingest(created_at: i.days.ago) }

          get :new

          expect(assigned(:ingests).size).to eq(5)
        end

        it 'shows the remainder on page 2' do
          6.times { |i| create_ingest(created_at: i.days.ago) }

          get :new, params: { page: 2 }

          expect(assigned(:ingests).size).to eq(1)
        end
      end

      describe 'batch summaries' do
        let(:ingest) { create_ingest }
        let(:batch) { create_batch(ingest) }

        it 'counts objects per status' do
          create_media_object(batch, 'COMPLETED', 'COMPLETED')
          create_media_object(batch, 'COMPLETED', 'FAILED')
          create_media_object(batch, 'PENDING')
          create_media_object(batch, 'PENDING', 'FAILED')

          get :new

          expect(assigned(:batches)).to eq(
            batch.id => { total: 4, pending: 1, completed: 2, failed: 2 }
          )
        end

        it 'counts correctly when nothing has failed' do
          create_media_object(batch, 'PENDING')

          get :new

          expect(assigned(:batches)).to eq(
            batch.id => { total: 1, pending: 1, completed: 0, failed: 0 }
          )
        end

        it 'leaves out ingests that have no batch yet' do
          ingest

          get :new

          expect(assigned(:batches)).to eq({})
        end
      end

      describe 'collections' do
        it 'nests child collections under their parent' do
          docs.push(solr_doc('parent1', 'Parent'), solr_doc('child1', 'Child', ['parent1']))

          get :new

          tree = assigned(:collections)
          expect(tree.map { |c| c[:id] }).to eq(['parent1'])
          expect(tree.first).to include(type: 'folder', text: 'Parent', parent_id: nil)
          expect(tree.first[:children].map { |c| c[:id] }).to eq(['child1'])
        end

        it 'drops collections whose parent is not in the results' do
          docs.push(solr_doc('orphan1', 'Orphan', ['missing-parent']))

          get :new

          expect(assigned(:collections)).to eq([])
        end

        it "queries Solr for the current user's collections" do
          get :new

          query, rows, options = solr_args
          expect(query).to include(user.email)
          expect(rows).to eq(100)
          expect(options[:fq]).to include('+is_collection_ssi:true', '+has_model_ssim:"DRI::QualifiedDublinCore"')
        end

        it 'restricts the query to a governing collection when one is given' do
          get :new, params: { governing: 'abc123' }

          expect(solr_args.last[:fq]).to include('+isGovernedBy_ssim:abc123')
        end

        it 'does not add a governing filter by default' do
          get :new

          expect(solr_args.last[:fq].grep(/isGovernedBy/)).to be_empty
        end
      end

      describe 'user directories' do
        context 'when the user directory exists' do
          before do
            FileUtils.mkdir_p(File.join(home, 'metadata'))
            FileUtils.mkdir_p(File.join(home, 'assets', 'nested'))
            FileUtils.mkdir_p(File.join(home, '.git'))
            FileUtils.mkdir_p(File.join(home, '__MACOSX'))
            FileUtils.touch(File.join(home, 'readme.txt'))
          end

          it 'assigns a tree of subdirectories, skipping files and system directories' do
            get :new

            tree = assigned(:user_dirs)
            expect(tree.map { |d| d[:text] }).to match_array(%w[assets metadata])
            expect(tree).to all(include(type: 'folder'))

            assets = tree.find { |d| d[:text] == 'assets' }
            expect(assets[:data]).to eq(path: 'assets')
            expect(assets[:children].map { |d| d[:data][:path] }).to eq(['assets/nested'])
          end
        end

        context 'when the user directory does not exist' do
          it 'assigns nil and still renders' do
            get :new

            expect(assigned(:user_dirs)).to be_nil
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end

    describe 'GET #show' do
      let(:batch) { create_batch(create_ingest) }

      it 'assigns the batch' do
        get :show, params: { id: batch.id }

        expect(response).to have_http_status(:ok)
        expect(assigned(:batch)).to eq(batch)
      end

      it 'lists all of the batch media objects by default' do
        objects = [create_media_object(batch, 'COMPLETED'), create_media_object(batch, 'FAILED')]
        create_media_object(create_batch(create_ingest), 'COMPLETED') # another batch

        get :show, params: { id: batch.id }

        expect(assigned(:media_objects).map(&:id)).to match_array(objects.map(&:id))
      end

      it 'filters media objects by part status' do
        create_media_object(batch, 'COMPLETED')
        failed = create_media_object(batch, 'FAILED')
        also_failed = create_media_object(batch, 'COMPLETED', 'FAILED')

        get :show, params: { id: batch.id, status: 'FAILED' }

        expect(assigned(:media_objects).map(&:id)).to match_array([failed.id, also_failed.id])
      end

      it 'paginates at 25 media objects per page' do
        26.times { create_media_object(batch) }

        get :show, params: { id: batch.id }

        expect(assigned(:media_objects).size).to eq(25)
      end

      it 'shows the remainder on page 2' do
        26.times { create_media_object(batch) }

        get :show, params: { id: batch.id, page: 2 }

        expect(assigned(:media_objects).size).to eq(1)
      end

      it 'raises not found for an unknown batch' do
        expect { get :show, params: { id: 0 } }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context "when the batch belongs to another user" do
        it 'does not show it' do
          other_batch = create_batch(create_ingest(other_user))

          expect { get :show, params: { id: other_batch.id } }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'PUT #update' do
      let(:batch) { create_batch(create_ingest) }

      it 'requeues only the failed media objects' do
        create_media_object(batch, 'COMPLETED')
        failed = create_media_object(batch, 'FAILED')
        mixed = create_media_object(batch, 'COMPLETED', 'FAILED')

        put :update, params: { id: batch.id }

        expect(Resque).to have_received(:enqueue).with(
          DRIBatchIngest::ProcessBatch, batch.id, a_collection_containing_exactly(failed.id, mixed.id)
        )
      end

      it 'ignores failed objects in other batches' do
        failed = create_media_object(batch, 'FAILED')
        create_media_object(create_batch(create_ingest), 'FAILED')

        put :update, params: { id: batch.id }

        expect(Resque).to have_received(:enqueue).with(DRIBatchIngest::ProcessBatch, batch.id, [failed.id])
      end

      it 'redirects to the ingests list' do
        put :update, params: { id: batch.id }

        expect(response).to redirect_to(ingests_path)
      end

      it 'raises not found for an unknown batch' do
        expect { put :update, params: { id: 0 } }.to raise_error(ActiveRecord::RecordNotFound)
        expect(Resque).not_to have_received(:enqueue)
      end

      context "when the batch belongs to another user" do
        it 'does not requeue it' do
          other_batch = create_batch(create_ingest(other_user))
          create_media_object(other_batch, 'FAILED')

          expect { put :update, params: { id: other_batch.id } }.to raise_error(ActiveRecord::RecordNotFound)
          expect(Resque).not_to have_received(:enqueue)
        end
      end
    end

    describe 'POST #create' do
      let(:params) do
        {
          collection_id: 'col1',
          metadata_path: 'ingest/metadata',
          asset_path: 'ingest/data',
          preservation_path: 'ingest/preservation'
        }
      end

      it 'creates an ingest for the current user' do
        expect { post :create, params: params }.to change(DRIBatchIngest::UserIngest, :count).by(1)

        expect(DRIBatchIngest::UserIngest.last.user_id).to eq(user.id)
      end

      it 'enqueues CreateManifest with the user home directory and the selected paths' do
        post :create, params: params

        ingest = DRIBatchIngest::UserIngest.last
        expect(Resque).to have_received(:enqueue).with(
          DRIBatchIngest::CreateManifest, ingest.id, home, user.email,
          'col1', 'ingest/metadata', 'ingest/data', 'ingest/preservation'
        )
      end

      it 'passes nil for optional paths that were not sent' do
        post :create, params: params.slice(:collection_id, :metadata_path)

        expect(Resque).to have_received(:enqueue).with(
          DRIBatchIngest::CreateManifest, anything, home, user.email, 'col1', 'ingest/metadata', nil, nil
        )
      end

      it 'passes blank optional paths as nil' do
        post :create, params: params.merge(asset_path: '', preservation_path: '')

        expect(Resque).to have_received(:enqueue).with(
          DRIBatchIngest::CreateManifest, anything, home, user.email, 'col1', 'ingest/metadata', nil, nil
        )
      end

      it 'redirects to the ingests list' do
        post :create, params: params

        expect(response).to redirect_to(ingests_path)
      end

      it 'ignores a client-supplied base directory' do
        post :create, params: params.merge(base_dir: '/etc')

        expect(Resque).to have_received(:enqueue).with(
          DRIBatchIngest::CreateManifest, anything, home, user.email, anything, anything, anything, anything
        )
      end

      bad_paths = [
        '../../other.user@example.com/files/metadata', # another user's directory
        '../../ingest.user@example.com.evil/files/x',  # sibling sharing a prefix
        'metadata/../../../..',                        # climbs out via a subdirectory
        '/etc'                                         # absolute path
      ]

      %i[metadata_path asset_path preservation_path].each do |key|
        bad_paths.each do |bad_path|
          it "rejects #{bad_path.inspect} in #{key} and enqueues nothing" do
            expect {
              post :create, params: params.merge(key => bad_path)
            }.not_to change(DRIBatchIngest::UserIngest, :count)

            expect(response).to have_http_status(:bad_request)
            expect(Resque).not_to have_received(:enqueue)
          end
        end
      end
    end
  end
end