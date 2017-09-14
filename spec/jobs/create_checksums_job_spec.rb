require 'rails_helper'
require 'ostruct'
require 'tempfile'

describe "workers" do

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    asset = File.join(fixture_path, 'SAMPLEA.mp3')
    tmp_file = Tempfile.new('SAMPLEA')
    FileUtils.cp(asset, tmp_file.path)
    uploadfile = { path: tmp_file.path, original_filename: 'SAMPLEA.mp3'}
    uploadhash = OpenStruct.new uploadfile
    tmpdir = Dir::tmpdir

    @user = FactoryGirl.create(:admin)

    @object = FactoryGirl.create(:sound)
     
    @gf = DRI::GenericFile.new
    @gf.apply_depositor_metadata(@user)
    @gf.digital_object = @object
    @gf.save

    actor = DRI::Asset::Actor.new(@gf, @user)
    actor.create_content(uploadhash, uploadhash.original_filename, 'content', 'audio/mpeg')
  end

  after(:each) do
    @object.destroy
    @user.destroy
    FileUtils.remove_dir(@tmp_assets_dir, :force => true)
  end
  
  describe CreateChecksumsJob do
  
    describe "run" do
      it "should create checksums when run function is called" do
        expect(@gf.checksum_md5).to be nil
        expect(@gf.checksum_sha256).to be nil
        job = CreateChecksumsJob.new(@gf.noid)
        job.run
        @gf.reload
        expect(@gf.checksum_md5).to_not be nil
        expect(@gf.checksum_sha256).to_not be nil
      end
    end
  
  end

end
