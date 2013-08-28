require 'spec_helper'

describe ApplicationController do

  describe 'set_access_permissions' do

    it "should correctly set the access values from the parameters" do
      controller.params = { :dri_model => { :private_metadata => "radio_public", :master_file => "radio_public" } }

      subject.send(:set_access_permissions, :dri_model)

      controller.params[:dri_model][:private_metadata].should eq("0")
      controller.params[:dri_model][:master_file].should eq("1")

      controller.params = { :dri_model => { :private_metadata => "radio_private", :master_file => "radio_private" } }

      subject.send(:set_access_permissions, :dri_model)

      controller.params[:dri_model][:private_metadata].should eq("1")
      controller.params[:dri_model][:master_file].should eq("0")
    end

    it "should handle the key not existing" do
      controller.params = { }

      expect {subject.send(:set_access_permissions, :dri_model)}.to_not raise_error
    end
  end

end
