describe "validators" do
  describe "virus_scan" do

    before do
      unless defined? ClamAV
        class ClamAV
          def self.instance
            new
          end

          def scanfile(file)
          end
        end
        @stubbed_clamav = true
      end
    end

    after do
      Object.send(:remove_const, :ClamAV) if @stubbed_clamav
    end

    it "should return 0 for a clean file" do
      if @stubbed_clamav
        expect_any_instance_of(ClamAV).to receive(:scanfile).and_return(0)
      end
      input_file = File.join(fixture_path, "SAMPLEA.mp3")
      expect { Validators.virus_scan(input_file) }.to_not raise_error()      
    end

    it "should raise an exception if a virus is found" do
      if @stubbed_clamav
        expect_any_instance_of(ClamAV).to receive(:scanfile).and_return(1)
      end
      input_file = File.join(fixture_path, "sample_virus.mp3")
      expect { Validators.virus_scan(input_file) }.to raise_error(DRI::Exceptions::VirusDetected)
    end

  end
end  
