describe "Storage::S3Interface" do

  before(:all) do
    @storage = Storage::S3Interface.new({stub_responses: true})
  end

  after(:all) do
   
  end

  it "should create a signed url" do
    expect_any_instance_of(Storage::S3Interface).to receive(:list_files).and_return(["x059d075t_crop16_9_width_200_thumbnail.png"])
    response = @storage.surrogate_url("1n79j1386", "x059d075t_crop16_9_width_200_thumbnail.png")

    endpoint = URI.parse(Settings.S3.server)
    signed_url = URI.parse(response)

    endpoint.scheme.should == signed_url.scheme
    endpoint.host.should == signed_url.host
    endpoint.port.should == signed_url.port
    signed_url.path.should == "/1n79j1386/x059d075t_crop16_9_width_200_thumbnail.png"

    signed_url.query.should include(Settings.S3.access_key_id)
    signed_url.query.should include("Signature=")
  end

end
