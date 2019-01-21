require "rails_helper"

describe SolrDocument do

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @collection = FactoryBot.create(:collection)
    @subcollection = FactoryBot.create(:collection)
    @object = FactoryBot.create(:sound)

    @subcollection.governing_collection = @collection
    @subcollection.governed_items << @object
    @subcollection.save

    @institute = Institute.new
    @institute.name = "Test Institute"
    @institute.url = "http://www.test.ie"
    @institute.save

    @institute_b = Institute.new
    @institute_b.name = "Second Test Institute"
    @institute_b.url = "http://www.secondtest.ie"
    @institute_b.save

    @dinstitute = Institute.new
    @dinstitute.name = "Depositing Test Institute"
    @dinstitute.url = "http://www.test.ie"
    @dinstitute.save

    @collection.institute = [@institute.name, @institute_b.name]
    @collection.depositing_institute = @dinstitute.name
    @collection.save
  end

  after(:each) do
    @collection.delete
    @institute.delete
    @dinstitute.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  context "when retrieving the depositing institute" do
    it "returns collection institute" do
      doc = SolrDocument.new(@collection.to_solr)
      expect(doc.depositing_institute).to eq @dinstitute
    end

    it "returns inherited collection institute" do
      doc = SolrDocument.new(@subcollection.to_solr)
      expect(doc.depositing_institute).to eq @dinstitute
    end

    it "returns collection institute for object" do
      doc = SolrDocument.new(@object.to_solr)
      expect(doc.depositing_institute).to eq @dinstitute
    end
  end

  context "when returning institutes" do
    it "returns all a collections institutes" do
      doc = SolrDocument.new(@collection.to_solr)
      expect(doc.institutes).to match_array([@institute, @institute_b])
    end

    it "returns inherited collection institutes" do
      doc = SolrDocument.new(@subcollection.to_solr)
      expect(doc.institutes).to match_array([@institute, @institute_b])
    end

    it "returns collection institutes for object" do
      doc = SolrDocument.new(@object.to_solr)
      expect(doc.institutes).to match_array([@institute, @institute_b])
    end
  end

  context "getting inherited fields" do
    it "returns a list of ancestor ids" do
      doc = SolrDocument.new(@object.to_solr)
      expect(doc.ancestor_ids).to eq [@subcollection.id, @collection.id]
    end

    it "returns the root collection" do
      doc = SolrDocument.new(@object.to_solr)
      expect(doc.root_collection.id).to eq @collection.id
    end

    it "returns the governing collection" do
      doc = SolrDocument.new(@object.to_solr)
      expect(doc.governing_collection.id).to eq @subcollection.id
    end
  end

  context "file methods" do
    it "should check for read master in object" do
      @object.master_file_access = 'public'
      @object.save
      @object.reload

      doc = SolrDocument.new(@object.to_solr)
      expect(doc.read_master?).to be true
    end

    it "should check for read master in ancestors" do
      @collection.master_file_access = 'public'
      @collection.save
      @collection.reload

      doc = SolrDocument.new(@object.to_solr)
      expect(doc.read_master?).to be true
    end

    it "first found is returned" do
      @collection.master_file_access = 'public'
      @collection.save
      @collection.reload

      @subcollection.master_file_access = 'private'
      @subcollection.save
      @subcollection.reload

      @object.master_file_access = nil
      @object.save
      @object.reload

      doc = SolrDocument.new(@object.to_solr)
      expect(doc.read_master?).to be false
    end

    it "should return the asset docs ordered or unordered" do
      labels = %w(g445rv188_DCLA.RDFA.006.08.tif g445rv188_DCLA.RDFA.006.20.tif g445rv188_DCLA.RDFA.006.07.tif g445rv188_DCLA.RDFA.006.13.tif)
      ordered_labels = %w(g445rv188_DCLA.RDFA.006.07.tif g445rv188_DCLA.RDFA.006.08.tif g445rv188_DCLA.RDFA.006.13.tif g445rv188_DCLA.RDFA.006.20.tif)

      labels.each { |l| @object.generic_files << DRI::GenericFile.create(label: l) }
      @object.save

      od = SolrDocument.find(@object.id)
      expect(od.assets(ordered: false).map(&:label)).to match_array(labels)
      expect(od.assets(ordered: true).map(&:label)).to eq ordered_labels
    end
  end

  context "collection methods" do
    it "should return total objects" do
      5.times do
        @collection.governed_items << FactoryBot.create(:sound)
      end
      @collection.save
      @collection.reload

      doc = SolrDocument.find(@collection.id)
      expect(doc.total_objects).to eq 6
    end

    it 'should return published only if requested' do
       2.times do
        @collection.governed_items << FactoryBot.create(:sound)
      end

      3.times do
        object = FactoryBot.create(:sound)
        object.status = 'published'
        object.save
        @collection.governed_items << object
      end

      @collection.save
      @collection.reload

      doc = SolrDocument.find(@collection.id)
      expect(doc.published_objects).to eq 3
    end

    context 'object type methods' do
      before(:each) do
        @solr_collection = SolrDocument.find(@collection.id)
        @solr_subcollection = SolrDocument.find(@subcollection.id)
        # @collection.governed_items will include subcollection
        # subcollection should only hold objects
        @solr_objects = @subcollection.governed_items.map do |item|
          SolrDocument.find(item.id)  
        end
      end
      describe 'collection?' do
        # collections includes subcollections
        it 'should return true for collections' do
          expect(@solr_collection.collection?).to be true
        end
        it 'should return true for subcollections' do
          expect(@solr_subcollection.collection?).to be true
        end
        it 'should return false for objects' do
          @solr_objects.each do |item|
            expect(item.collection?).to be false
          end
        end
      end

      describe 'object?' do
        # any other type i.e. collections
        it 'should return false for collections' do
          expect(@solr_collection.object?).to be false
        end
        it 'should return false for subcollections' do
          expect(@solr_subcollection.object?).to be false
        end
        it 'should return true for objects' do
          @solr_objects.each do |item|
            expect(item.object?).to be true
          end
        end
      end

      describe 'root_collection?' do
        it 'should return true for root collections' do
          expect(@solr_collection.root_collection?).to be true
        end
        it 'should return false for subcollections' do
          expect(@solr_subcollection.root_collection?).to be false
        end
        it 'should return false for objects' do
          @solr_objects.each do |item|
            expect(item.root_collection?).to be false
          end
          # require 'byebug'
          # byebug

          # FactoryBot.factories
        end
      end
    end
  end
end
