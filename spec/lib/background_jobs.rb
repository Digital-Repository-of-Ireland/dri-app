require 'spec_helper'
require 'ostruct'
  
describe "workers" do
  
  before :all do
    @object = DRI::Model::DigitalObject.construct(:audio, {:title => "test title",
                                                           :rights => "test rights",
                                                           :language => "en"})
    @object.save
    asset = File.join(fixture_path, "SAMPLEA.mp3")
    uploadfile = { :read =>  File.read( asset ), :original_filename => "SAMPLEA.mp3"}
    uploadhash = OpenStruct.new uploadfile
    tmpdir = Dir::tmpdir
    file = LocalFile.new
    file.add_file(uploadhash, {:fedora_id => @object.id, :ds_id => "masterContent", :directory => tmpdir} )
    file.save
    @object.save
  end
  
  describe CreateMp3 do
  
    describe "executable" do
      it "should have an appropriate executable defined for mp3" do
         Settings.plugins.ffmpeg_path.should_not be nil
         CreateMp3.executable.should == Settings.plugins.ffmpeg_path
      end
    end
  
    describe "output_options" do
      it "should have output options defined for mp3" do
        CreateMp3.output_options.should_not be nil
      end
    end
  
    describe "transcode" do
      it "should transcode a file and output mp3" do
        tmpdir = Dir::tmpdir
        input_file = File.join(fixture_path, "SAMPLEA.mp3")
        output_file = File.join(tmpdir, "testout.mp3")
        options = "-y -ac 2 -ab 96k -ar 44100"
        CreateMp3.transcode(input_file, options, output_file)
        File.exists?(output_file).should be true
      end
    end
  
    describe "perform" do
      it "should create ogg when perform function is called" do
        CreateMp3.perform(@object.id)
        @object.reload
        # once mp3 referenced in datastream we should retrieve it to test
      end
    end
  
  end
  
  describe CreateOgg do
  
    describe "executable" do
      it "should have an appropriate executable defined for ogg" do
         Settings.plugins.ffmpeg_path.should_not be nil
         CreateOgg.executable.should == Settings.plugins.ffmpeg_path
      end
    end
  
    describe "output_options" do
      it "should have output options defined for ogg" do
        CreateOgg.output_options.should_not be nil
      end
    end
  
    describe "transcode" do
      it "should transcode a file and output ogg" do
        tmpdir = Dir::tmpdir
        input_file = File.join(fixture_path, "SAMPLEA.mp3")
        output_file = File.join(tmpdir, "testout.mp3")
        options = "-y -ac 2 -ab 96k -ar 44100"
        CreateOgg.transcode(input_file, options, output_file)
        File.exists?(output_file).should be true
      end
    end
  
    describe "perform" do
      it "should create ogg when perform function is called" do
        CreateOgg.perform(@object.id)
        @object.reload
        # once ogg referenced in datastream we should retrieve it to test
      end
    end
  
  end
  
  
  describe CreateChecksums do
  
    describe "perform" do
      it "should create checksums when perform function is called" do
        @object.resource_md5.first.should be nil
        @object.resource_sha256.first.should be nil
        CreateChecksums.perform(@object.id)
        @object.reload
        @object.resource_md5.first.should_not be nil
        @object.resource_sha256.first.should_not be nil
      end
    end
  
  end


  describe VerifyAudio do
    VerifyAudio.perform(@object.id)
  end


  describe VerifyPdf do
    VerifyPdf.perform(@object.id)
  end


end
