require 'rails_helper'
require 'csv'

describe "CreateExportJob" do
  
  before(:all) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
    
    @login_user = FactoryGirl.create(:collection_manager)

    @collection = FactoryGirl.create(:collection)
    @collection[:status] = "draft"
    @collection.save

    @object = FactoryGirl.create(:sound)
    @object[:status] = "draft"
    @object.save

    @object2 = FactoryGirl.create(:sound)
    @object2[:status] = "draft"
    @object2.save

    @collection.governed_items << @object
    @collection.governed_items << @object2
    @collection.save
  end

  after(:all) do
    @collection.delete
    @login_user.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end
  
  describe "run" do
      
    it "creates an export file" do
      delivery = double
      expect(delivery).to receive(:deliver_now).with(no_args)

      expect(JobMailer).to receive(:export_ready_mail)
      .and_return(delivery)
      CreateExportJob.perform(@collection.id, {'title' => 'Title', 'description' => 'Description'}, @login_user.email)

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
      CreateExportJob.perform(@collection.id, {'title' => 'Title', 'description' => 'Description'}, @login_user.email)
      
      storage = StorageService.new
      bucket_name = "users.#{Mail::Address.new(@login_user.email).local}"
      key = "#{@collection_id}"
      files = storage.get_surrogates(bucket_name, key)
      file_contents = open(files.values.first) { |f| f.read }
      csv = CSV.parse(file_contents)

      expect(csv[1].drop(1)).to eql(csv[2].drop(1))

      expect(csv[1][1]).to eql(@object.title.join(','))
      expect(csv[1][2]).to eql(@object.description.join(','))
    end 
  end

end