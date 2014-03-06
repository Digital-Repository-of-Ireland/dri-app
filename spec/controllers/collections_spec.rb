require 'spec_helper'

describe CollectionsController do
  include Devise::TestHelpers

  before do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user
  end

  describe 'DELETE destroy' do

    it 'should delete a collection' do
      @collection = Batch.new
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
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
      @object.save

      @collection.governed_items << @object

      @collection.governed_items.length.should == 1

      delete :destroy, :id => @collection.id

      expect { ActiveFedora::Base.find(@object.id) }.to raise_error(ActiveFedora::ObjectNotFoundError)
      expect { ActiveFedora::Base.find(@collection.id) }.to raise_error(ActiveFedora::ObjectNotFoundError)
    end

  end

end
