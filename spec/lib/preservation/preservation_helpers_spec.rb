# frozen_string_literal: true

require "rails_helper"

RSpec.describe Preservation::PreservationHelpers do
  let(:helper_class) { Class.new { include Preservation::PreservationHelpers } }
  subject(:helper) { helper_class.new }

  before do
    allow(Settings.dri).to receive(:files).and_return("storage-root")
  end

  describe "#version_string" do
    it "formats a version number as v0001-style, zero-padded to 4 digits" do
      expect(helper.version_string(1)).to eq("v0001")
      expect(helper.version_string(23)).to eq("v0023")
      expect(helper.version_string(1234)).to eq("v1234")
    end
  end

  describe "#build_hash_dir" do
    it "splits a 9-character id into 2-character path segments (real-shaped example)" do
      # NOTE: File.join("", "st") actually produces "/st" in Ruby (an
      # empty string is still a path component, joined with "/"), and
      # that leading slash carries through the rest of the joins.
      expect(helper.build_hash_dir("st74cs991")).to eq("/st/74/cs/99/st74cs991")
    end

    it "splits a 10-character id into up to 4 two-character segments" do
      expect(helper.build_hash_dir("ab12cd34ef")).to eq("/ab/12/cd/34/ab12cd34ef")
    end

    it "stops early for a short id rather than reading past its length" do
      expect(helper.build_hash_dir("ab12")).to eq("/ab/12/ab12")
    end

    it "handles an odd-length id" do
      expect(helper.build_hash_dir("abc")).to eq("/ab/abc")
    end
  end

  describe "#path_for_type" do
    it "routes 'content' to content_path" do
      expect(helper.path_for_type("content", "obj1", 1)).to eq(helper.content_path("obj1", 1))
    end

    it "routes 'metadata' to metadata_path" do
      expect(helper.path_for_type("metadata", "obj1", 1)).to eq(helper.metadata_path("obj1", 1))
    end

    it "returns nil for any other type" do
      expect(helper.path_for_type("manifests", "obj1", 1)).to be_nil
    end
  end

  describe "path composition" do
    it "builds aip_dir from the storage root and hashed object id" do
      expect(helper.aip_dir("ab12")).to eq(File.join(helper.local_storage_dir, "ab/12/ab12"))
    end

    it "builds version_path by appending the formatted version to aip_dir's shape" do
      expect(helper.version_path("ab12", 3)).to eq(File.join(helper.local_storage_dir, "ab/12/ab12", "v0003"))
    end

    it "builds data_path under version_path" do
      expect(helper.data_path("ab12", 3)).to eq(File.join(helper.version_path("ab12", 3), "data"))
    end

    it "builds content_path under data_path" do
      expect(helper.content_path("ab12", 3)).to eq(File.join(helper.data_path("ab12", 3), "content"))
    end

    it "builds metadata_path under data_path" do
      expect(helper.metadata_path("ab12", 3)).to eq(File.join(helper.data_path("ab12", 3), "metadata"))
    end

    it "builds manifest_path under version_path (not data_path)" do
      expect(helper.manifest_path("ab12", 3)).to eq(File.join(helper.version_path("ab12", 3), "manifests"))
    end
  end

  describe "#make_dir" do
    it "creates the given paths" do
      tmp_root = Dir.mktmpdir
      paths = [File.join(tmp_root, "a"), File.join(tmp_root, "b", "c")]

      helper.make_dir(paths)

      expect(Dir.exist?(paths[0])).to be true
      expect(Dir.exist?(paths[1])).to be true

      FileUtils.remove_dir(tmp_root, force: true)
    end

    it "raises an InternalError and logs if directory creation fails" do
      allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::EACCES)

      expect { helper.make_dir(["/some/path"]) }.to raise_error(DRI::Exceptions::InternalError)
    end
  end

  describe "#attached_file_match?" do
    it "matches when the file's content md5 equals the given md5" do
      file = double("file", content: "hello", to_xml: "not this")
      md5 = Checksum.md5_string("hello")

      expect(helper.attached_file_match?(file, md5)).to be true
    end

    it "matches when the file's xml representation md5 equals the given md5, even if content does not" do
      file = double("file", content: "hello", to_xml: "<xml>hello</xml>")
      md5 = Checksum.md5_string("<xml>hello</xml>")

      expect(helper.attached_file_match?(file, md5)).to be true
    end

    it "does not match when neither content nor xml md5 matches" do
      file = double("file", content: "hello", to_xml: "<xml>hello</xml>")

      expect(helper.attached_file_match?(file, "not-a-real-md5")).to be false
    end
  end
end