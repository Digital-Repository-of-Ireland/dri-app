require 'spec_helper'
require 'solr/query'

# declare an exclusion filter
RSpec.configure { |c| c.filter_run_excluding(slow: true) }

describe 'PublishJob' do
  before(:each) do
    @collection = DRI::Batch.with_standard :qdc
    @collection[:title] = ['A collection']
    @collection[:description] = ['This is a Collection']
    @collection[:rights] = ['This is a statement about the rights associated with this object']
    @collection[:publisher] = ['RnaG']
    @collection[:type] = ['Collection']
    @collection[:creation_date] = ['1916-01-01']
    @collection[:published_date] = ['1916-04-01']
    @collection[:status] = 'draft'
    @collection.save

    @object = DRI::Batch.with_standard :qdc
    @object[:title] = ['An Audio Title']
    @object[:rights] = ['This is a statement about the rights associated with this object']
    @object[:role_hst] = ['Collins, Michael']
    @object[:contributor] = ['DeValera, Eamonn', 'Connolly, James']
    @object[:language] = ['ga']
    @object[:description] = ['This is an Audio file']
    @object[:published_date] = ['1916-04-01']
    @object[:creation_date] = ['1916-01-01']
    @object[:source] = ['CD nnn nuig']
    @object[:geographical_coverage] = ['Dublin']
    @object[:temporal_coverage] = ['1900s']
    @object[:subject] = ['Ireland', 'something else']
    @object[:type] = ['Sound']
    @object[:status] = 'reviewed'
    @object.save

    @collection.governed_items << @object
    @collection.save
  end

  after(:each) do
    @object.delete
    @collection.delete
  end

  describe 'run' do
    it "should set a collection\'s reviewed objects status to published" do
      Sufia.queue.stub(:push).with(an_instance_of(MintDoiJob))
      job = PublishJob.new(@collection.id)
      job.run

      @collection.reload
      @object.reload

      expect(@collection.status).to eql('published')
      expect(@object.status).to eql('published')
    end

    it 'should not set an object to published if within an unreviewed sub-collection' do
      @reviewed = DRI::Batch.with_standard :qdc
      @reviewed[:title] = ['A Text Title']
      @reviewed[:rights] = ['This is a statement about the rights associated with this object']
      @reviewed[:contributor] = ['DeValera, Eamonn']
      @reviewed[:language] = ['ga']
      @reviewed[:description] = ['This is an Audio file']
      @reviewed[:published_date] = ['1916-04-01']
      @reviewed[:creation_date] = ['1916-01-01']
      @reviewed[:source] = ['CD nnn nuig']
      @reviewed[:geographical_coverage] = ['Dublin']
      @reviewed[:temporal_coverage] = ['1900s']
      @reviewed[:subject] = ['Ireland']
      @reviewed[:type] = ['Sound']
      @reviewed[:status] = 'reviewed'
      @reviewed.save

      @subcollection = DRI::Batch.with_standard :qdc
      @subcollection[:title] = ['A collection']
      @subcollection[:description] = ['This is a sub-collection']
      @subcollection[:rights] = ['This is a statement about the rights associated with this object']
      @subcollection[:publisher] = ['DRI']
      @subcollection[:type] = ['Collection']
      @subcollection[:creation_date] = ['1916-01-01']
      @subcollection[:published_date] = ['1916-04-01']
      @subcollection[:status] = 'draft'
      @subcollection.governed_items << @reviewed
      @subcollection.save

      @collection.governed_items << @subcollection
      @collection.save

      Sufia.queue.stub(:push).with(an_instance_of(MintDoiJob))
      job = PublishJob.new(@collection.id)
      job.run

      @collection.reload
      @subcollection.reload
      @reviewed.reload

      expect(@collection.status).to eql('published')
      expect(@subcollection.status).to eql('draft')
      expect(@object.status).to eql('reviewed')
    end

    it "should not set a collection\'s draft objects to published" do
      @draft = DRI::Batch.with_standard :qdc
      @draft[:title] = ['An Audio Title']
      @draft[:rights] = ['This is a statement about the rights associated with this object']
      @draft[:role_hst] = ['Collins, Michael']
      @draft[:contributor] = ['"DeValera, Eamonn", "Connolly, James"']
      @draft[:language] = ['ga']
      @draft[:description] = ['This is an Audio file']
      @draft[:published_date] = ['1916-04-01']
      @draft[:creation_date] = ['1916-01-01']
      @draft[:source] = ['CD nnn nuig']
      @draft[:geographical_coverage] = ['Dublin']
      @draft[:temporal_coverage] = ['1900s']
      @draft[:subject] = ['Ireland', 'something else']
      @draft[:type] = ['Sound']
      @draft[:status] = 'draft'
      @draft.save

      @collection.governed_items << @draft
      @collection.save

      job = PublishJob.new(@collection.id)
      job.run

      @collection.reload
      @draft.reload

      expect(@draft.status).to eql('draft')

      @draft.delete
    end

    it 'should queue a doi job when publishing an object' do
      DoiConfig = OpenStruct.new(username: 'user', password: 'password', prefix: '10.5072', base_url: 'http://www.dri.ie/repository', publisher: 'Digital Repository of Ireland')
      Settings.doi.enable = true

      job = PublishJob.new(@collection.id)

      Sufia.queue.should_receive(:push).with(an_instance_of(MintDoiJob)).twice
      job.run

      @collection.reload
      @object.reload

      expect(@collection.status).to eql('published')
      expect(@object.status).to eql('published')

      DoiConfig = nil
      Settings.doi.enable = false
    end

    @slow
    it 'should handle more than 10 objects', slow: true do
      20.times do
        o = FactoryGirl.create(:sound)
        o[:status] = ['reviewed']
        o.save

        @collection.governed_items << o
      end

      @collection.save

      job = PublishJob.new(@collection.id)
      job.run

      q = "collection_id_sim:\"#{@collection.id}\" AND status_ssim:published"
      expect(ActiveFedora::SolrService.count(q)).to eq(21)
    end
  end
end
