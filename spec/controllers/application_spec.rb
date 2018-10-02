describe ApplicationController do

  it "should handle the key not existing" do
    skip
    controller.params = { }

    expect {subject.send(:set_access_permissions, :dri_model)}.to_not raise_error
  end

end
