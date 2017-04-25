require 'rails_helper'
require 'csv'

describe "CreateExportJob" do
  
  before(:all) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
    Settings.filesystem.directory = @tmp_assets_dir

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
    let(:export_file) { Dir[File.join(@tmp_assets_dir, "users.#{Mail::Address.new(@login_user.email).local}", "#{@collection.id}*.csv")] }
      
    it "creates an export file" do
      delivery = double
      expect(delivery).to receive(:deliver_now).with(no_args)

      expect(JobMailer).to receive(:export_ready_mail)
      .and_return(delivery)
      CreateExportJob.perform(@collection.id, {'title' => 'Title', 'description' => 'Description'}, @login_user.email)

      expect(export_file).to_not be_empty
    end

    it "adds the objects metadata to the export" do
      csv = CSV.read(export_file[0])

      expect(csv[1].drop(1)).to eql(csv[2].drop(1))

      expect(csv[1][1]).to eql(@object.title.join(','))
      expect(csv[1][2]).to eql(@object.description.join(','))
    end 
  end

end