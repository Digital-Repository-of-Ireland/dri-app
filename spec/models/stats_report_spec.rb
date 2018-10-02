describe StatsReport do
  
  before(:each) do
    @object = FactoryBot.create(:image)
  end

  after(:each) do
    @object.delete
  end

  context "Mime_type stats" do
    it "should return mime type counts" do
      generic_file1 = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file1.batch = @object
      generic_file1.mime_type = "application/pdf"
      generic_file1.save

      generic_file2 = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file2.batch = @object
      generic_file2.mime_type = "image/jpeg"
      generic_file2.save

      generic_file3 = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file3.batch = @object
      generic_file3.mime_type = "application/pdf"
      generic_file3.save

      @object.update_index

      mime_types = StatsReport.mime_type_counts

      expect(mime_types['pdf ()']).to eq 2
      expect(mime_types['jpeg ()']).to eq 1
    end
  end

  context "file size count" do
    it "should return total file size" do
      generic_file1 = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file1.batch = @object
      generic_file1.file_size = [200]
      generic_file1.save

      generic_file2 = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file2.batch = @object
      generic_file2.file_size = [100]
      generic_file2.save

      @object.update_index

      file_size = StatsReport.total_file_size
      expect(file_size).to eq 300
    end
  end

end
