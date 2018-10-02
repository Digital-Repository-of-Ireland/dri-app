describe LocalFile do

  before(:each) do
    @file = LocalFile.new(fedora_id: "1234567", ds_id: "masterContent")
    @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
    @tmpdir = Dir.mktmpdir
  end

  after(:each) do
    @file.destroy
    FileUtils.remove_dir(@tmpdir, :force => true)
  end

  it "should accept an uploaded file" do
    @file.add_file(@uploaded, { batch_id: 'test', :file_name => "SAMPLEA.mp3", :directory => @tmpdir })
    expect(File.exist?(File.join(@tmpdir, "SAMPLEA.mp3"))).to be true 
    File.unlink(File.join(@tmpdir, "SAMPLEA.mp3"))
  end

  it "should delete a file" do
    @file.add_file(@uploaded, { batch_id: 'test', :file_name => "SAMPLEA.mp3", :directory => @tmpdir })
    expect(File.exist?(File.join(@tmpdir, "SAMPLEA.mp3"))).to be true
    @file.delete_file
    expect(File.exist?(File.join(@tmpdir, "SAMPLEA.mp3"))).to_not be true
  end

end
