# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::AccessControls::CsvExporter do
  describe ".generate" do
    let(:collection) do
      double("collection").tap do |c|
        allow(c).to receive(:[]).with("title_tesim").and_return(["My Collection"])
      end
    end

    it "includes the header row" do
      allow(CollectionPermissions).to receive(:with_inherited_permissions).with(collection).and_return([])
      allow(CollectionPermissions).to receive(:with_custom_permissions).with(collection).and_return([])

      csv = described_class.generate([collection])

      expect(csv.lines.first.strip).to eq("collection,title,users,asset file access")
    end

    it "includes one row per inherited object and one per custom object" do
      inherited_object = double("inherited")
      allow(inherited_object).to receive(:[]).with("title_tesim").and_return(["Inherited Object"])

      custom_object = double("custom")
      allow(custom_object).to receive(:[]).with("title_tesim").and_return(["Custom Object"])

      allow(CollectionPermissions).to receive(:with_inherited_permissions).with(collection).and_return([inherited_object])
      allow(CollectionPermissions).to receive(:with_custom_permissions).with(collection).and_return([custom_object])

      allow(DRI::AccessControls::PermissionsSummary).to receive(:for).with(inherited_object).and_return(
        read_access: "public", read_label: "Public", assets: "public", assets_label: "Public assets"
      )
      allow(DRI::AccessControls::PermissionsSummary).to receive(:for).with(custom_object).and_return(
        read_access: "restricted", read_label: "Restricted", assets: "private", assets_label: "Private assets"
      )

      csv = described_class.generate([collection])
      rows = CSV.parse(csv, headers: true)

      expect(rows.size).to eq(2)
      expect(rows[0]["title"]).to eq("Inherited Object")
      expect(rows[0]["users"]).to eq("public")
      expect(rows[0]["asset file access"]).to eq("Public assets")
      expect(rows[1]["title"]).to eq("Custom Object")
      expect(rows[1]["collection"]).to eq("My Collection")
    end

    it "produces no data rows for a collection with no inherited or custom objects" do
      allow(CollectionPermissions).to receive(:with_inherited_permissions).with(collection).and_return([])
      allow(CollectionPermissions).to receive(:with_custom_permissions).with(collection).and_return([])

      csv = described_class.generate([collection])
      rows = CSV.parse(csv, headers: true)

      expect(rows.size).to eq(0)
    end

    it "processes multiple collections in order" do
      collection2 = double("collection2")
      allow(collection2).to receive(:[]).with("title_tesim").and_return(["Second Collection"])

      object1 = double("object1")
      allow(object1).to receive(:[]).with("title_tesim").and_return(["Object One"])
      object2 = double("object2")
      allow(object2).to receive(:[]).with("title_tesim").and_return(["Object Two"])

      allow(CollectionPermissions).to receive(:with_inherited_permissions).with(collection).and_return([object1])
      allow(CollectionPermissions).to receive(:with_custom_permissions).with(collection).and_return([])
      allow(CollectionPermissions).to receive(:with_inherited_permissions).with(collection2).and_return([object2])
      allow(CollectionPermissions).to receive(:with_custom_permissions).with(collection2).and_return([])

      allow(DRI::AccessControls::PermissionsSummary).to receive(:for).and_return(
        read_access: "public", read_label: "Public", assets: "public", assets_label: "Public assets"
      )

      csv = described_class.generate([collection, collection2])
      rows = CSV.parse(csv, headers: true)

      expect(rows.map { |r| r["collection"] }).to eq(["My Collection", "Second Collection"])
    end
  end
end
