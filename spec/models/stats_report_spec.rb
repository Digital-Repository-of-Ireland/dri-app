require 'rails_helper'

describe StatsReport do

  let(:tmp_assets_dir) { Dir.mktmpdir }

  before(:each) do
    Settings.dri.files = tmp_assets_dir
    @object = FactoryBot.create(:image)
    @object2 = FactoryBot.create(:image)
  end

  after(:each) do
    @object.delete
    @object2.delete
    FileUtils.remove_dir(tmp_assets_dir, force: true)
  end

  context "Mime_type stats" do
    it "should return mime type counts" do
      generic_file1 = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file1.digital_object = @object
      generic_file1.mime_type = "application/pdf"
      generic_file1.save

      generic_file2 = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file2.digital_object = @object
      generic_file2.mime_type = "image/jpeg"
      generic_file2.save

      generic_file3 = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file3.digital_object = @object2
      generic_file3.mime_type = "application/pdf"
      generic_file3.save

      @object.update_index
      @object2.update_index

      mime_types = StatsReport.mime_type_counts

      expect(mime_types['application/pdf']).to eq 2
      expect(mime_types['image/jpeg']).to eq 1

      generic_file1.delete
      generic_file2.delete
      generic_file3.delete
    end
  end

  context "file size count" do
    it "should return total file size" do
      generic_file1 = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file1.digital_object = @object
      generic_file1.file_size = 200
      generic_file1.save

      generic_file2 = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file2.digital_object = @object
      generic_file2.file_size = 100
      generic_file2.save

      @object.update_index

      file_size = StatsReport.total_file_size
      expect(file_size).to eq 300
      generic_file1.delete
      generic_file2.delete
    end
  end

end
