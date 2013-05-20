require 'spec_helper'
require 'ostruct'
  
describe "workers" do
  
  before :each do
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
    @object.reload

    AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                        :access_key_id => Settings.S3.access_key_id,
                                        :secret_access_key => Settings.S3.secret_access_key)
    bucket = @object.pid.sub('dri:', '')
    begin
      AWS::S3::Bucket.create(bucket)
puts "creating bucket #{bucket}"
    rescue AWS::S3::ResponseError, AWS::S3::S3Exception => e
      logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
      raise Exceptions::InternalError
    end
    AWS::S3::Base.disconnect!()
  end

  after :each do
    AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                        :access_key_id => Settings.S3.access_key_id,
                                        :secret_access_key => Settings.S3.secret_access_key)
puts "deleting bucket #{@object.pid.sub('dri:', '')}"
    AWS::S3::Bucket.delete(@object.pid.sub('dri:', ''), :force => true)
    AWS::S3::Base.disconnect!()
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
      it "should create mp3 when perform function is called" do
        CreateMp3.perform(@object.id)
        @object.reload

        AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                            :access_key_id => Settings.S3.access_key_id,
                                            :secret_access_key => Settings.S3.secret_access_key)

        begin
          bucket = AWS::S3::Bucket.find(@object.pid.sub('dri:', ''))
        rescue AWS::S3::ResponseError, AWS::S3::S3Exception => e
          #report failue
        end
        filename = "#{@object.pid}-mp3-#{Settings.mp3_out_options.channel}-#{Settings.mp3_out_options.bitrate}-#{Settings.mp3_out_options.frequency}.mp3"
        files = []
        bucket.each do |fileobject|
          files.push(fileobject.key)
        end
        files.should include filename

        AWS::S3::Base.disconnect!()
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

        AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                            :access_key_id => Settings.S3.access_key_id,
                                            :secret_access_key => Settings.S3.secret_access_key)

        begin
          bucket = AWS::S3::Bucket.find(@object.pid.sub('dri:', ''))
        rescue AWS::S3::ResponseError, AWS::S3::S3Exception => e
          #report failue
        end
        filename = "#{@object.pid}-ogg-#{Settings.ogg_out_options.channel}-#{Settings.ogg_out_options.bitrate}-#{Settings.ogg_out_options.frequency}.ogg"
        files = []
        bucket.each do |fileobject|
          files.push(fileobject.key)
        end
        files.should include filename

        AWS::S3::Base.disconnect!()
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
    it "should verify an audio file" do
      @object.verified.should be nil    
      VerifyAudio.perform(@object.id)
      @object.reload
      @object.verified.should == "success"
    end

    it "should fail when the audio is invalid" do
      object2 = DRI::Model::DigitalObject.construct(:audio, {:title => "test title",
                                                           :rights => "test rights",
                                                           :language => "en"})
      object2.save
      asset = File.join(fixture_path, "sample_invalid_audio.mp3")
      uploadfile = { :read =>  File.read( asset ), :original_filename => "sample_invalid_audio.mp3"}
      uploadhash = OpenStruct.new uploadfile
      tmpdir = Dir::tmpdir
      file = LocalFile.new
      file.add_file(uploadhash, {:fedora_id => object2.id, :ds_id => "masterContent", :directory => tmpdir} )
      file.save
      object2.save
      object2.verified.should be nil
      VerifyAudio.perform(object2.id)
      object2.reload
      object2.verified.should == "UnknownMimeType" 
    end

  end


end
