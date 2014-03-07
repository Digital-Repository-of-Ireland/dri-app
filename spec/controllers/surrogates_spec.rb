require 'spec_helper'

describe SurrogatesController do
  include Devise::TestHelpers

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @collection = Batch.new
    @collection[:title] = ["A collection"]
    @collection[:description] = ["This is a Collection"]
    @collection[:rights] = ["This is a statement about the rights associated with this object"]
    @collection[:publisher] = ["RnaG"]
    @collection[:type] = ["Collection"]
    @collection[:creation_date] = ["1916-01-01"]
    @collection[:published_date] = ["1916-04-01"]
    @collection[:status] = ["draft"]
    @collection.save

    @object = Batch.new    
    @object[:title] = ["An Audio Title"]
    @object[:rights] = ["This is a statement about the rights associated with this object"]
    @object[:role_hst] = ["Collins, Michael"]
    @object[:contributor] = ["DeValera, Eamonn", "Connolly, James"]
    @object[:language] = ["ga"]
    @object[:description] = ["This is an Audio file"]
    @object[:published_date] = ["1916-04-01"]
    @object[:creation_date] = ["1916-01-01"]
    @object[:source] = ["CD nnn nuig"]
    @object[:geographical_coverage] = ["Dublin"]
    @object[:temporal_coverage] = ["1900s"]
    @object[:subject] = ["Ireland","something else"]
    @object[:type] = ["Sound"]
    @object[:status] = ["draft"]
    @object.save

    @collection.governed_items << @object    
    @collection.save
    
    @gf = GenericFile.new
    @gf.batch = @object
    @gf.save
  end

  after(:each) do
    @gf.delete
    @object.delete
    @collection.delete

    @login_user.delete
  end

  describe 'update' do

    it 'should update a collections surrogates' do
      request.env["HTTP_REFERER"] = "/"
      Sufia.queue.should_receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, :id => @collection.id
    end

    it 'should update an objects surrogates' do
      request.env["HTTP_REFERER"] = "/"
      Sufia.queue.should_receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, :id => @object.id
    end

    it 'should update multiple files' do
      @gf2 = GenericFile.new
      @gf2.batch = @object
      @gf2.save
      
      request.env["HTTP_REFERER"] = "/"
      Sufia.queue.should_receive(:push).with(an_instance_of(CharacterizeJob)).twice
      put :update, :id => @object.id

      @gf2.delete
    end

  end

end
