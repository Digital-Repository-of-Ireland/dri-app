require 'spec_helper'

describe CollectionsController do
  include Devise::TestHelpers

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user
  end

  describe 'DELETE destroy' do

    it 'should delete a collection' do
      @collection = FactoryGirl.create(:collection)
      @object = FactoryGirl.create(:audio)

      @collection.governed_items << @object

      @collection.governed_items.length.should == 1

      delete :destroy, :id => @collection.id

      expect { ActiveFedora::Base.find(@object.id) }.to raise_error(ActiveFedora::ObjectNotFoundError)
      expect { ActiveFedora::Base.find(@collection.id) }.to raise_error(ActiveFedora::ObjectNotFoundError)
    end

  end

end
