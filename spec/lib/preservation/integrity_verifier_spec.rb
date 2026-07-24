# frozen_string_literal: true

require "rails_helper"

RSpec.describe Preservation::IntegrityVerifier do
  let(:object) do
    double(
      "object",
      alternate_id: "abc12",
      object_version: 2,
      attached_files: { descMetadata: double("desc", content: "xml-content", to_xml: "xml-content") }
    )
  end

  subject(:verifier) { described_class.new(object) }

  before { allow(Settings.dri).to receive(:files).and_return("/tmp/storage-root") }

  # This is the key regression test for the fix: the original code found
  # the metadata group via `g.group_id = 'metadata'` (assignment, not
  # comparison), which always matched whichever group happened to be
  # *first* in the list, regardless of its actual group_id. Listing
  # 'content' before 'metadata' here means that bug would have grabbed
  # the wrong group - whose path_hash has no 'descMetadata.xml' key -
  # and blown up (or silently mismatched) rather than verifying
  # correctly.
  it "finds the metadata group by comparing group_id, not by grabbing whichever group is listed first" do
    metadata_group = double(
      "metadata_group",
      group_id: "metadata",
      path_hash: { "descMetadata.xml" => double("sig", md5: Checksum.md5_string("xml-content")) }
    )
    content_group = double("content_group", group_id: "content")

    file_inventory = double("file_inventory", groups: [content_group, metadata_group])
    storage_object_version = double(
      "storage_object_version",
      file_inventory: file_inventory,
      version_id: 2,
      verify_version_storage: double("verify", verified: true, subentities: [])
    )
    storage_object = double("storage_object", current_version: storage_object_version)
    allow(Moab::StorageObject).to receive(:new).and_return(storage_object)

    result = verifier.call

    expect(result[:verified]).to be true
    expect(result[:versions]).to be true
    expect(result[:attached_files][:metadata]).to be true
  end

  it "reports the object version mismatching the storage version" do
    metadata_group = double(
      "metadata_group",
      group_id: "metadata",
      path_hash: { "descMetadata.xml" => double("sig", md5: Checksum.md5_string("xml-content")) }
    )
    file_inventory = double("file_inventory", groups: [metadata_group])
    storage_object_version = double(
      "storage_object_version",
      file_inventory: file_inventory,
      version_id: 99,
      verify_version_storage: double("verify", verified: true, subentities: [])
    )
    storage_object = double("storage_object", current_version: storage_object_version)
    allow(Moab::StorageObject).to receive(:new).and_return(storage_object)

    result = verifier.call

    expect(result[:versions]).to be false
    expect(result[:verified]).to be false
  end

  it "reports a failed verification (rather than raising) when an error occurs" do
    allow(Moab::StorageObject).to receive(:new).and_raise(StandardError, "boom")

    result = verifier.call

    expect(result[:verified]).to be false
    expect(result[:output]).to eq("boom")
  end
end
