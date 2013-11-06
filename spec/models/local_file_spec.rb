require 'spec_helper'

describe LocalFile do

  before(:each) do
    @file = LocalFile.new
    @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
  end

  it "should accept an uploaded file" do
    @file.add_file(@uploaded, { :directory => Dir.tmpdir, :fedora_id => "dri:1234", :ds_id => "masterContent", :version => "0" })
    File.exist?(File.join(Dir.tmpdir, "SAMPLEA.mp3")).should be_true 
    File.unlink(File.join(Dir.tmpdir, "SAMPLEA.mp3"))
  end

  it "should delete a file" do
    @file.add_file(@uploaded, { :directory => Dir.tmpdir, :fedora_id => "dri:1234", :ds_id => "masterContent", :version => "0" })
    File.exist?(File.join(Dir.tmpdir, "SAMPLEA.mp3")).should be_true
    @file.delete_file
    File.exist?(File.join(Dir.tmpdir, "SAMPLEA.mp3")).should_not be_true
  end

  it "should clean up file on destroy" do
    @file.add_file(@uploaded, { :directory => Dir.tmpdir, :fedora_id => "dri:1234", :ds_id => "masterContent", :version => "0" })
    File.exist?(File.join(Dir.tmpdir, "SAMPLEA.mp3")).should be_true
    @file.destroy
    File.exist?(File.join(Dir.tmpdir, "SAMPLEA.mp3")).should_not be_true
  end

end
