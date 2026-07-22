# frozen_string_literal: true

require "rails_helper"

# These are integration-style specs rather than isolated unit tests,
# deliberately: Preservator's collaborators (SignatureCatalogLookup,
# ManifestManager, IntegrityVerifier) lean heavily on the Moab gem's own
# API, which isn't something this refactor's author has independent
# documentation for beyond how it's used in the source. Rather than
# risk mis-mocking that API, these specs exercise the real Moab gem
# against a real tmpdir, the same way this app's own existing specs
# already do (e.g. `Preservation::Preservator.new(@collection).preserve(['descMetadata'])`
# used throughout the Objects/Collections controller specs).
#
# NOTE: assumes a freshly-created object's object_version starts at 1
# (matching ManifestManager#create_or_update's `object.object_version == 1`
# check for "is this the first version"). If that assumption is wrong,
# the "first preserve creates version 1" tests below would need
# adjusting.
RSpec.describe Preservation::Preservator do
  let(:tmp_assets_dir) { Dir.mktmpdir }

  before { Settings.dri.files = tmp_assets_dir }
  after { FileUtils.remove_dir(tmp_assets_dir, force: true) }

  let(:object) { FactoryBot.create(:sound) }
  after { object.destroy if DRI::Identifier.object_exists?(object.alternate_id) }

  before do
    # The :sound factory itself already calls Preservator#preserve (via
    # its own after(:create) hook), which creates version 1's Moab
    # directories on disk. Wipe that out here so every test below can
    # exercise create_moab_dirs/preserve/etc. from a genuinely clean
    # slate, instead of colliding with directories the factory already
    # made.
    Preservation::Preservator.new(object).remove_moab_dirs(true)
  end

  subject(:preservator) { described_class.new(object) }

  describe "#create_moab_dirs" do
    it "creates the version, metadata, and content directories" do
      preservator.create_moab_dirs

      expect(Dir.exist?(preservator.version_path(object.alternate_id, preservator.version))).to be true
      expect(Dir.exist?(preservator.metadata_path(object.alternate_id, preservator.version))).to be true
      expect(Dir.exist?(preservator.content_path(object.alternate_id, preservator.version))).to be true
    end

    it "raises an InternalError if the directory already exists for this version" do
      # create_moab_dirs's own guard checks the *manifests* directory
      # specifically, but create_moab_dirs itself only ever creates
      # version_path/metadata_path/content_path (see the make_dir call
      # below) - the manifests directory only comes into existence as a
      # side effect of actually writing manifests, so a real preserve is
      # needed to trigger the collision, not just a second bare call.
      preservator.preserve(["descMetadata"])

      expect { preservator.create_moab_dirs }.to raise_error(DRI::Exceptions::InternalError)
    end
  end

  describe "#preserve" do
    it "returns true on a successful first preserve" do
      expect(preservator.preserve(["descMetadata"])).to be true
    end

    it "writes an attributes.json file" do
      preservator.preserve(["descMetadata"])

      attributes_path = File.join(preservator.metadata_path(object.alternate_id, preservator.version), "attributes.json")
      expect(File.exist?(attributes_path)).to be true
    end

    it "writes the requested datastream as xml" do
      preservator.preserve(["descMetadata"])

      ds_path = File.join(preservator.metadata_path(object.alternate_id, preservator.version), "descMetadata.xml")
      expect(File.exist?(ds_path)).to be true
    end

    it "succeeds with no datastreams requested (attributes only)" do
      expect(preservator.preserve).to be true
    end

    it "creates a new version's manifests after the object's version is bumped" do
      preservator.preserve(["descMetadata"])

      object.increment_version
      object.save

      next_preservator = described_class.new(object)
      expect(next_preservator.preserve(["descMetadata"])).to be true
      expect(next_preservator.version).to eq(preservator.version + 1)
    end

    it "returns false and stops early if writing the attributes fails" do
      allow_any_instance_of(Preservation::AttributesWriter).to receive(:write_attributes).and_return(false)

      expect(preservator.preserve(["descMetadata"])).to be false
    end

    it "returns false if writing a requested datastream fails" do
      allow_any_instance_of(Preservation::AttributesWriter).to receive(:write_datastream).and_return(false)

      expect(preservator.preserve(["descMetadata"])).to be false
    end
  end

  describe "#verify" do
    it "reports verified: true after a successful preserve" do
      preservator.preserve(["descMetadata"])

      result = preservator.verify

      expect(result[:verified]).to be true
      expect(result[:versions]).to be true
      expect(result[:attached_files][:metadata]).to be true
    end
  end

  describe "#existing_filepath and #signature_catalog" do
    it "finds a previously-preserved file in the signature catalog" do
      preservator.preserve(["descMetadata"])
      ds_path = File.join(preservator.metadata_path(object.alternate_id, preservator.version), "descMetadata.xml")

      expect(preservator.existing_filepath(ds_path)).to be_present
    end

    it "returns nil for a file that was never preserved" do
      preservator.preserve(["descMetadata"])

      tmp_file = Tempfile.new("not-preserved")
      tmp_file.write("something not preserved")
      tmp_file.rewind

      expect(preservator.existing_filepath(tmp_file.path)).to be_nil

      tmp_file.close
      tmp_file.unlink
    end

    it "raises a MoabError when there is no current signature catalog to read" do
      expect { preservator.signature_catalog }.to raise_error(DRI::Exceptions::MoabError)
    end
  end

  describe "#remove_moab_dirs" do
    it "does nothing when no attribute files exist yet" do
      expect { preservator.remove_moab_dirs }.not_to raise_error
      expect(Dir.exist?(preservator.aip_dir(object.alternate_id))).to be false
    end

    it "removes the AIP directory for a draft (unpublished) object" do
      preservator.preserve(["descMetadata"])

      preservator.remove_moab_dirs

      expect(Dir.exist?(preservator.aip_dir(object.alternate_id))).to be false
    end

    it "does not remove the AIP directory for a previously-published object unless forced" do
      object.status = "published"
      object.save
      preservator.preserve(["descMetadata"])

      preservator.remove_moab_dirs

      expect(Dir.exist?(preservator.aip_dir(object.alternate_id))).to be true
    end

    it "removes the AIP directory for a previously-published object when forced" do
      object.status = "published"
      object.save
      preservator.preserve(["descMetadata"])

      preservator.remove_moab_dirs(true)

      expect(Dir.exist?(preservator.aip_dir(object.alternate_id))).to be false
    end
  end

  describe "#create_manifests / #update_manifests / #create_or_update_manifests" do
    it "create_or_update_manifests creates fresh manifests for a first-version object" do
      preservator.create_moab_dirs
      attributes_writer = Preservation::AttributesWriter.new(object, preservator.version)
      attributes_writer.write_attributes

      expect(preservator.create_or_update_manifests([attributes_writer.attributes_path])).to be true
    end

    it "falls back to creating fresh manifests when update_manifests is called for a version with no previous manifest at all" do
      # No version has ever been preserved for this object - simulates
      # calling update for a version with nothing to build on, rather
      # than the normal "preserve version 1, then update to version 2"
      # sequence.
      version = 3
      preservator_at_version = described_class.new(object, version)
      preservator_at_version.create_moab_dirs
      attributes_writer = Preservation::AttributesWriter.new(object, version)
      attributes_writer.write_attributes

      result = preservator_at_version.update_manifests(modified: { "metadata" => [attributes_writer.attributes_path] })

      expect(result).to be true
      expect(Dir.exist?(preservator_at_version.manifest_path(object.alternate_id, version))).to be true
    end
  end
end