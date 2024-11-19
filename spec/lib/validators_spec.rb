require 'rails_helper'

describe "validators" do

  describe "virus_scan" do

    before do
      unless defined? Clamby
        class Clamby
          def self.safe?(file)
          end

	        def self.virus?(file)
          end
        end
        @stubbed_clamby = true
      end
    end

    after do
      Object.send(:remove_const, :Clamby) if @stubbed_clamby
    end

    it "should return 0 for a clean file" do
      if @stubbed_clamby
        expect(Clamby).to receive(:safe?).and_return(true)
      end
      input_file = File.join(fixture_paths, "SAMPLEA.mp3")
      expect { Validators.virus_scan(input_file) }.to_not raise_error()
    end

    it "should raise an exception if a virus is found" do
      if @stubbed_clamby
        expect(Clamby).to receive(:safe?).and_return(false)
      end
      input_file = File.join(fixture_paths, "sample_virus.mp3")
      expect { Validators.virus_scan(input_file) }.to raise_error(DRI::Exceptions::VirusDetected)
    end

  end
end
