require 'csv'

describe "CreateExportJob" do
  
  before(:each) do
    Settings.reload_from_files(
      Rails.root.join(fixture_path, "settings-fs.yml").to_s
    )
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
    Settings.filesystem.directory = @tmp_assets_dir

    @login_user = FactoryBot.create(:collection_manager)

    @collection = FactoryBot.create(:collection)
    @collection[:status] = "draft"
    @collection.save

    @object = FactoryBot.create(:sound)
    @object[:status] = "draft"
    @object.save

    @object2 = FactoryBot.create(:sound)
    @object2[:status] = "draft"
    @object2.save

    @collection.governed_items << @object
    @collection.governed_items << @object2
    @collection.save
  end

  after(:each) do
    @collection.delete
    @login_user.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
    Settings.reload_from_files(
      Rails.root.join("config", "settings.yml").to_s
    )
  end
  
  describe "run" do
      
    it "creates an export file" do
      delivery = double
      expect(delivery).to receive(:deliver_now).with(no_args)

      expect(JobMailer).to receive(:export_ready_mail)
      .and_return(delivery)
      CreateExportJob.perform(@collection.id, {'title' => 'Title', 'description' => 'Description', 'subject' => 'Subjects'}, @login_user.email)

      storage = StorageService.new
      bucket_name = "users.#{Mail::Address.new(@login_user.email).local}"
      key = "#{@collection_id}"

      expect(storage.surrogate_exists?(bucket_name, key)).to be true
    end

    it "adds the objects metadata to the export" do
      delivery = double
      expect(delivery).to receive(:deliver_now).with(no_args)

      expect(JobMailer).to receive(:export_ready_mail)
      .and_return(delivery)
      CreateExportJob.perform(@collection.id, {'title' => 'Title', 'description' => 'Description', 'subject' => 'Subjects'}, @login_user.email)

      storage = StorageService.new
      bucket_name = "users.#{Mail::Address.new(@login_user.email).local}"
      key = "#{@collection_id}"
      files = storage.get_surrogates(bucket_name, key)
      file_contents = open(files.values.first) { |f| f.read }
      csv = CSV.parse(file_contents)

      expect(csv[1][1]).to eql(@object.title.first)
      expect(csv[1][2]).to eql(@object.description.first)
      expect(csv[2][1]).to eql(@object.title.first)
      expect(csv[2][2]).to eql(@object.description.first)
    end

    it "creates headers for fields with multiple values" do
      delivery = double
      expect(delivery).to receive(:deliver_now).with(no_args)

      expect(JobMailer).to receive(:export_ready_mail)
      .and_return(delivery)
      CreateExportJob.perform(@collection.id, {'title' => 'Title', 'description' => 'Description', 'subject' => 'Subjects'}, @login_user.email)

      storage = StorageService.new
      bucket_name = "users.#{Mail::Address.new(@login_user.email).local}"
      key = "#{@collection_id}"
      files = storage.get_surrogates(bucket_name, key)
      file_contents = open(files.values.first) { |f| f.read }
      csv = CSV.parse(file_contents, headers: true)
      row = csv.first
      
      expect(row.key?('Subjects')).to be true
      expect(row.key?('Subjects_1')).to be true
    end
  end

end
