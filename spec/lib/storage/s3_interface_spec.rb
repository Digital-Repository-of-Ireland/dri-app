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

    expect(endpoint.scheme).to eql signed_url.scheme
    expect(endpoint.host).to eql signed_url.host
    expect(endpoint.port).to eql signed_url.port

    prefix = Settings.S3.bucket_prefix ? "#{Settings.S3.bucket_prefix}.#{Rails.env}." : ''
    
    expect(signed_url.path).to eql "/#{prefix}1n79j1386/x059d075t_crop16_9_width_200_thumbnail.png"

    expect(signed_url.query).to include(Settings.S3.access_key_id)
    expect(signed_url.query).to include("Signature=")
  end

end
