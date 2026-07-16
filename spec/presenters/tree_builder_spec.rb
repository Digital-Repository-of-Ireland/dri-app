# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::AccessControls::TreeBuilder do
  describe ".entries_for" do
    let(:document) do
      double("document", id: "col1").tap do |d|
        allow(d).to receive(:[]).with("title_tesim").and_return(["My Collection"])
        allow(d).to receive(:[]).with("ancestor_id_ssim").and_return(nil)
      end
    end

    before do
      allow(DRI::AccessControls::PermissionsSummary).to receive(:for).with(document).and_return(
        read_access: "public", read_label: "Public", assets: "public", assets_label: "Public assets"
      )
      allow(CollectionPermissions).to receive(:count_with_inherited_permissions).with(document).and_return(0)
      allow(CollectionPermissions).to receive(:with_custom_permissions).with(document).and_return([])
    end

    it "builds a single folder entry when there are no inherited or custom objects" do
      entries = described_class.entries_for([document])

      expect(entries.size).to eq(1)
      expect(entries.first).to include(id: "col1", type: "folder", parent_id: nil)
      expect(entries.first[:text]).to eq("My Collection: Public Public assets")
    end

    it "sets parent_id from the first ancestor id when ancestors are present" do
      allow(document).to receive(:[]).with("ancestor_id_ssim").and_return(["parent1", "parent2"])

      entries = described_class.entries_for([document])

      expect(entries.first[:parent_id]).to eq("parent1")
    end

    it "adds an inherit-objects summary entry when there are inherited objects" do
      allow(CollectionPermissions).to receive(:count_with_inherited_permissions).with(document).and_return(5)

      entries = described_class.entries_for([document])
      inherit_entry = entries.find { |e| e[:id] == "col1-inherit" }

      expect(inherit_entry).to be_present
      expect(inherit_entry[:parent_id]).to eq("col1")
    end

    it "does not add an inherit-objects entry when the count is zero" do
      entries = described_class.entries_for([document])

      expect(entries.map { |e| e[:id] }).not_to include("col1-inherit")
    end

    it "adds a custom-objects folder and one item entry per custom object" do
      custom_object = double("object", id: "obj1")
      allow(custom_object).to receive(:[]).with("title_tesim").and_return(["Custom Object"])
      allow(CollectionPermissions).to receive(:with_custom_permissions).with(document).and_return([custom_object])
      allow(DRI::AccessControls::PermissionsSummary).to receive(:for).with(custom_object).and_return(
        read_access: "restricted", read_label: "Restricted", assets: "private", assets_label: "Private assets"
      )

      entries = described_class.entries_for([document])

      custom_folder = entries.find { |e| e[:id] == "col1-custom" }
      expect(custom_folder).to be_present
      expect(custom_folder[:parent_id]).to eq("col1")

      item = entries.find { |e| e[:id] == "obj1" }
      expect(item).to be_present
      expect(item[:parent_id]).to eq("col1-custom")
      expect(item[:text]).to eq("Custom Object: Restricted Private assets")
    end

    it "does not add a custom-objects entry when there are no custom objects" do
      entries = described_class.entries_for([document])

      expect(entries.map { |e| e[:id] }).not_to include("col1-custom")
    end

    it "processes multiple collections, concatenating their entries" do
      document2 = double("document2", id: "col2")
      allow(document2).to receive(:[]).with("title_tesim").and_return(["Second Collection"])
      allow(document2).to receive(:[]).with("ancestor_id_ssim").and_return(nil)
      allow(DRI::AccessControls::PermissionsSummary).to receive(:for).with(document2).and_return(
        read_access: "public", read_label: "Public", assets: "public", assets_label: "Public assets"
      )
      allow(CollectionPermissions).to receive(:count_with_inherited_permissions).with(document2).and_return(0)
      allow(CollectionPermissions).to receive(:with_custom_permissions).with(document2).and_return([])

      entries = described_class.entries_for([document, document2])

      expect(entries.map { |e| e[:id] }).to contain_exactly("col1", "col2")
    end
  end

  describe ".nest" do
    it "nests child entries under their parent and returns only top-level entries" do
      entries = [
        { id: "a", parent_id: nil },
        { id: "b", parent_id: "a" },
        { id: "c", parent_id: "a" }
      ]

      nested = described_class.nest(entries)

      expect(nested.size).to eq(1)
      expect(nested.first[:id]).to eq("a")
      expect(nested.first[:children].map { |c| c[:id] }).to contain_exactly("b", "c")
    end

    it "supports multiple levels of nesting" do
      entries = [
        { id: "a", parent_id: nil },
        { id: "b", parent_id: "a" },
        { id: "c", parent_id: "b" }
      ]

      nested = described_class.nest(entries)

      expect(nested.first[:children].first[:id]).to eq("b")
      expect(nested.first[:children].first[:children].first[:id]).to eq("c")
    end

    it "returns multiple top-level entries when there are several roots" do
      entries = [
        { id: "a", parent_id: nil },
        { id: "b", parent_id: nil }
      ]

      nested = described_class.nest(entries)

      expect(nested.map { |e| e[:id] }).to contain_exactly("a", "b")
    end

    it "drops an entry whose parent_id does not match any known entry (matches the original's exact behavior)" do
      entries = [{ id: "a", parent_id: "missing-parent" }]

      nested = described_class.nest(entries)

      expect(nested).to eq([])
    end

    it "gives every entry an empty :children array by default" do
      entries = [{ id: "a", parent_id: nil }]

      nested = described_class.nest(entries)

      expect(nested.first[:children]).to eq([])
    end
  end
end
