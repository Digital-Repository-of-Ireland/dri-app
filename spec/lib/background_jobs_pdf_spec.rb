require 'spec_helper'
require 'ostruct'
  
describe "workers" do
  
  before :each do
    @object = DRI::Model::DigitalObject.construct(:pdfdoc, {:title => "test title",
                                                           :rights => "test rights",
                                                           :language => "en"})
    @object.save
    asset = File.join(fixture_path, "sample_pdf.pdf")
    uploadfile = { :read =>  File.read( asset ), :original_filename => "sample_pdf.pdf"}
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
    AWS::S3::Bucket.delete(@object.pid.sub('dri:', ''), :force => true)
    AWS::S3::Base.disconnect!()
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


  describe VerifyPdf do
    it "should verify a pdf file" do
      @object.verified.should be nil    
      VerifyPdf.perform(@object.id)
      @object.reload
      @object.verified.should == "success"
    end

    it "should fail when the pdf is invalid" do
      object2 = DRI::Model::DigitalObject.construct(:pdfdoc, {:title => "test title",
                                                           :rights => "test rights",
                                                           :language => "en"})
      object2.save
      asset = File.join(fixture_path, "sample_invalid_doc.pdf")
      uploadfile = { :read =>  File.read( asset ), :original_filename => "sample_invalid_doc.pdf"}
      uploadhash = OpenStruct.new uploadfile
      tmpdir = Dir::tmpdir
      file = LocalFile.new
      file.add_file(uploadhash, {:fedora_id => object2.id, :ds_id => "masterContent", :directory => tmpdir} )
      file.save
      object2.save
      object2.verified.should be nil
      VerifyPdf.perform(object2.id)
      object2.reload
      object2.verified.should == "UnknownMimeType" 
    end

  end


end
