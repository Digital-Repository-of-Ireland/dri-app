require 'rails_helper'
require 'zip'
require 'bagit'

describe CreateArchiveJob do

  before(:each) do
    @tmp_upload_dir = Dir.mktmpdir
    @tmp_assets_dir = Dir.mktmpdir
    @tmp_downloads_dir = Dir.mktmpdir

    Settings.dri.uploads = @tmp_upload_dir
    Settings.dri.downloads = @tmp_downloads_dir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:admin)
    @collection = FactoryBot.create(:collection)

    @object = FactoryBot.create(:image)
    @object[:status] = "draft"
    @object.save

    @collection.governed_items << @object
    @collection.save

    allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

    @object.master_file_access = 'public'
    @object.edit_users_string = @login_user.email
    @object.read_users_string = @login_user.email
    @object.save
    @object.reload

    @generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
    @generic_file.digital_object = @object
    @generic_file.apply_depositor_metadata(@login_user.email)
    @generic_file.label = "sample_image.jpeg"
    options = {}
    options[:mime_type] = "image/jpeg"
    options[:file_name] = "sample_image.jpg"

    uploaded = Rack::Test::UploadedFile.new(File.join(fixture_paths, "sample_image.jpeg"), "image/jpeg")
    @generic_file.add_file uploaded, options
    @generic_file.save
    file_id = @generic_file.alternate_id

    storage = StorageService.new
    storage.create_bucket(@object.alternate_id)
    storage.store_surrogate(@object.alternate_id, File.join(fixture_paths, "sample_image.jpeg"), "#{@generic_file.alternate_id}_full_size_web_format.jpg")
  end

  after(:each) do
    @collection.delete
    @login_user.delete
    FileUtils.remove_dir(@tmp_upload_dir, force: true)
    FileUtils.remove_dir(@tmp_downloads_dir, force: true)
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  it 'should create an archive for download' do
    delivery = double
    expect(delivery).to receive(:deliver_now).with(no_args)

    expect(JobMailer).to receive(:archive_ready_mail)
      .and_return(delivery)

    CreateArchiveJob.perform(@object.alternate_id, @login_user.email)

    zip_file = Dir[File.join("#{@tmp_downloads_dir}","#{@object.alternate_id}_*")]
    expect(zip_file).not_to be_empty

    zip = Zip::File.open(zip_file.first)
    expect(zip.entries.map(&:name).any? { |entry| entry.include?("#{@generic_file.alternate_id}_optimised_sample_image.jpeg") }).to be true
  end

  it 'should create an valid bagit archive' do
    delivery = double
    expect(delivery).to receive(:deliver_now).with(no_args)

    expect(JobMailer).to receive(:archive_ready_mail)
      .and_return(delivery)

    CreateArchiveJob.perform(@object.alternate_id, @login_user.email)

    zip_file = Dir[File.join("#{@tmp_downloads_dir}","#{@object.alternate_id}_*")]
    expect(zip_file).not_to be_empty

    Zip::File.open(zip_file.first) do |zip_file|
    # Handle entries one by one
      zip_file.each do |entry|
        fpath = File.join("#{@tmp_downloads_dir}","#{@object.alternate_id}", entry.to_s)
        FileUtils.mkdir_p(File.dirname(fpath))
        # the block is for handling an existing file.
        # returning true will overwrite the files.
        zip_file.extract(entry, fpath){ true }
      end
    end

    bag = BagIt::Bag.new File.join("#{@tmp_downloads_dir}","#{@object.alternate_id}")
    expect(bag.valid?).to be true
  end

  it 'should create an archive for object containing non image surrogates' do
    @generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
    @generic_file.digital_object = @object
    @generic_file.apply_depositor_metadata(@login_user.email)
    @generic_file.label = "sample_audio.mp3"
     options = {}
    options[:mime_type] = "audio/mp3"
    options[:file_name] = "sample_audio.mp3"

    uploaded = Rack::Test::UploadedFile.new(File.join(fixture_paths, "sample_audio.mp3"), "audio/mp3")
    @generic_file.add_file uploaded, options
    @generic_file.save
    file_id = @generic_file.alternate_id

    storage = StorageService.new
    storage.create_bucket(@object.alternate_id)
    storage.store_surrogate(@object.alternate_id, File.join(fixture_paths, "sample_audio.mp3"), "#{@generic_file.alternate_id}_mp3.mp3")

    delivery = double
    expect(delivery).to receive(:deliver_now).with(no_args)

    expect(JobMailer).to receive(:archive_ready_mail)
      .and_return(delivery)

    CreateArchiveJob.perform(@object.alternate_id, @login_user.email)

    zip_file = Dir[File.join("#{@tmp_downloads_dir}","#{@object.alternate_id}_*")]
    expect(zip_file).not_to be_empty

    zip = Zip::File.open(zip_file.first)
    expect(zip.entries.map(&:name).any? { |entry| entry.include?("#{@generic_file.alternate_id}_optimised_sample_audio.mp3") }).to be true
  end
end
