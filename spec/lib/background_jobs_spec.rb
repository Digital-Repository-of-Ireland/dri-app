require 'spec_helper'
require 'ostruct'
require 'tempfile'

describe "workers" do

  before do
    asset = File.join(fixture_path, "SAMPLEA.mp3")
    tmp_file = Tempfile.new('SAMPLEA')
    FileUtils.cp(asset, tmp_file.path)
    uploadfile = { :path =>  tmp_file.path, :original_filename => "SAMPLEA.mp3"}
    uploadhash = OpenStruct.new uploadfile
    tmpdir = Dir::tmpdir
     
    @gf = GenericFile.new
    @gf.save

    @file = LocalFile.new
    @file.add_file(uploadhash, {:fedora_id => @gf.id, :ds_id => "content", :directory => tmpdir} )
    @file.save

    @url = "file://#{@file.path}"
    @gf.update_file_reference "content", :url=>@url, :mimeType=>'audio/mpeg'
  end

  after do
    @file.delete
    @gf.delete
  end
  
  describe CreateChecksumsJob do
  
    describe "run" do
      it "should create checksums when run function is called" do
        @gf.checksum_md5.should be nil
        @gf.checksum_sha256.should be nil
        job = CreateChecksumsJob.new(@gf.id)
        job.run
        @gf.reload
        @gf.checksum_md5.should_not be nil
        @gf.checksum_sha256.should_not be nil
      end
    end
  
  end

end
