require 'spec_helper'

describe LocalFile do

  before(:each) do
    @file = LocalFile.new
    @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
    @tmpdir = Dir.mktmpdir
  end

  it "should accept an uploaded file" do
    @file.add_file(@uploaded, { :directory => @tmpdir, :fedora_id => "dri:1234", :ds_id => "masterContent", :version => "0" })
    File.exist?(File.join(@tmpdir, "SAMPLEA.mp3")).should be true 
    File.unlink(File.join(@tmpdir, "SAMPLEA.mp3"))

    FileUtils.remove_dir(@tmpdir, :force => true)
  end

  it "should delete a file" do
    @file.add_file(@uploaded, { :directory => @tmpdir, :fedora_id => "dri:1234", :ds_id => "masterContent", :version => "0" })
    File.exist?(File.join(@tmpdir, "SAMPLEA.mp3")).should be true
    @file.delete_file
    File.exist?(File.join(@tmpdir, "SAMPLEA.mp3")).should_not be true
 
    FileUtils.remove_dir(@tmpdir, :force => true)
  end

  it "should clean up file on destroy" do
    @file.add_file(@uploaded, { :directory => @tmpdir, :fedora_id => "dri:1234", :ds_id => "masterContent", :version => "0" })
    File.exist?(File.join(@tmpdir, "SAMPLEA.mp3")).should be true
    @file.destroy
    File.exist?(File.join(@tmpdir, "SAMPLEA.mp3")).should_not be true

    FileUtils.remove_dir(@tmpdir, :force => true)
  end

end
