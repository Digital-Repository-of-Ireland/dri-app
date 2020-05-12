require 'rails_helper'

describe 'DRI::Solr::Document::Collection' do
  include DRI::Duplicable

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
  end

  after(:each) do
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe "#duplicates" do
    before(:each) do
      @collection = FactoryBot.create(:collection)

      @object = FactoryBot.create(:sound)
      @object[:status] = "draft"
      checksum_metadata(@object)
      @object.save

      @object2 = FactoryBot.create(:sound)
      @object2[:status] = "draft"
      checksum_metadata(@object2)
      @object2.save

      @object3 = FactoryBot.create(:sound)
      @object3[:status] = "draft"
      @object3[:title] = ["Not a Duplicate"]
      checksum_metadata(@object3)
      @object3.save

      @collection.governed_items << @object
      @collection.governed_items << @object2
      @collection.governed_items << @object3
    end

    after(:each) do
      @collection.delete
    end

    it 'should return a count of duplicates' do
      doc = SolrDocument.new(@collection.to_solr)

      expect(doc.duplicate_total).to eq(2)
    end

    it 'should get the solr documents of duplicates' do
      doc = SolrDocument.new(@collection.to_solr)

      duplicates = doc.duplicates[1]
      ids = duplicates.map(&:id)

      expect(ids.count).to eq(2)
      expect(ids).to include(@object.noid)
      expect(ids).to include(@object2.noid)
      expect(ids).to_not include(@object3.noid)
    end
  end

  describe "#duplicates sort" do
    before(:each) do
      @collection2 = FactoryBot.create(:collection)

      @object = FactoryBot.create(:sound)
      @object[:status] = "draft"
      @object[:title] = "Object A"
      checksum_metadata(@object)
      @object.save

      @object2 = FactoryBot.create(:sound)
      @object2[:status] = "draft"
      @object2[:title] = "Object B"
      checksum_metadata(@object2)
      @object2.save

      @object3 = FactoryBot.create(:sound)
      @object3[:status] = "draft"
      @object3[:title] = ["Object A"]
      checksum_metadata(@object3)
      @object3.save

      @object4 = FactoryBot.create(:sound)
      @object4[:status] = "draft"
      @object4[:title] = "Object B"
      checksum_metadata(@object4)
      @object4.save

      @collection2.governed_items << @object
      @collection2.governed_items << @object2
      @collection2.governed_items << @object3
      @collection2.governed_items << @object4
    end

    after(:each) do
      @collection2.delete
    end

    it 'should get the sorted solr documents of duplicates' do
      doc = SolrDocument.new(@collection2.to_solr)

      duplicates = doc.duplicates[1]
      titles = duplicates.map(&:title)
      expect([@object.title, @object2.title, @object.title, @object2.title]).to eq titles

      duplicates = doc.duplicates('title_sorted_ssi asc')[1]
      titles = duplicates.map(&:title)
      expect([@object.title, @object.title, @object2.title, @object2.title]).to eq titles
    end
  end
end



