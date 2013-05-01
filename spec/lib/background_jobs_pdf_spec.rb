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
    @object.save
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
