require 'spec_helper'

describe LocalFile do

  before(:each) do
    @file = LocalFile.new(fedora_id: "dri:1234", ds_id: "masterContent")
    @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
    @tmpdir = Dir.mktmpdir
  end

  after(:each) do
    FileUtils.remove_dir(@tmpdir, :force => true)
  end

  it "should accept an uploaded file" do
    @file.add_file(@uploaded, { :directory => @tmpdir })
    File.exist?(File.join(@tmpdir, "SAMPLEA.mp3")).should be true 
    File.unlink(File.join(@tmpdir, "SAMPLEA.mp3"))
  end

  it "should delete a file" do
    @file.add_file(@uploaded, { :directory => @tmpdir })
    File.exist?(File.join(@tmpdir, "SAMPLEA.mp3")).should be true
    @file.delete_file
    File.exist?(File.join(@tmpdir, "SAMPLEA.mp3")).should_not be true
  end

  it "should clean up file on destroy" do
    @file.add_file(@uploaded, { :directory => @tmpdir })
    File.exist?(File.join(@tmpdir, "SAMPLEA.mp3")).should be true
    @file.destroy
    File.exist?(File.join(@tmpdir, "SAMPLEA.mp3")).should_not be true
  end

  it "should increment the version" do
    @file.add_file(@uploaded, { :directory => @tmpdir })
    @file.save
    @file.add_file(@uploaded, { :directory => @tmpdir })
    expect(@file.version).to be(1)
  end

end
