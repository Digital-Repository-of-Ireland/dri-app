# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Edm::AssetSelector do
  let(:edm_settings) do
    double(
      "edm_settings",
      _3d: "3D_OBJECT",
      video: ["MOVING IMAGE"],
      sound: ["SOUND RECORDING"],
      text: "TEXT",
      image: ["STILL IMAGE", "PHOTOGRAPH"]
    )
  end

  before do
    allow(Settings).to receive(:edm).and_return(edm_settings)
  end

  describe ".edm_type" do
    it "returns 3D when the types include the configured 3D type" do
      expect(described_class.edm_type(["3d_object"])).to eq("3D")
    end

    it "returns VIDEO when types intersect the configured video set" do
      expect(described_class.edm_type(["moving image"])).to eq("VIDEO")
    end

    it "returns SOUND when types intersect the configured sound set" do
      expect(described_class.edm_type(["sound recording"])).to eq("SOUND")
    end

    it "returns TEXT when types include the configured text type" do
      expect(described_class.edm_type(["text"])).to eq("TEXT")
    end

    it "returns IMAGE when types intersect the configured image set" do
      expect(described_class.edm_type(["photograph"])).to eq("IMAGE")
    end

    it "returns INVALID when nothing matches" do
      expect(described_class.edm_type(["dataset"])).to eq("INVALID")
    end

    it "upcases input types before comparing, so matching is case-insensitive" do
      expect(described_class.edm_type(["Still Image"])).to eq("IMAGE")
    end
  end

  describe ".clean" do
    it "keeps assets that have a file type and are not XML surrogates" do
      pdf = { "file_type_tesim" => ["text"], "mime_type_tesim" => ["application/pdf"] }
      xml = { "file_type_tesim" => ["text"], "mime_type_tesim" => ["text/xml"] }

      expect(described_class.clean([pdf, xml])).to eq([pdf])
    end

    it "excludes assets without a file_type_tesim key" do
      no_type = { "mime_type_tesim" => ["application/pdf"] }

      expect(described_class.clean([no_type])).to eq([])
    end
  end

  describe ".find_by_type" do
    it "finds the first asset whose file_type_tesim includes the given type" do
      video = { "file_type_tesim" => ["video"] }
      audio = { "file_type_tesim" => ["audio"] }

      expect(described_class.find_by_type([video, audio], "audio")).to eq(audio)
    end

    it "returns nil when no asset matches" do
      expect(described_class.find_by_type([{ "file_type_tesim" => ["video"] }], "audio")).to be_nil
    end
  end

  describe ".mainfile_for_type" do
    let(:video_asset) { { "file_type_tesim" => ["video"] } }
    let(:audio_asset) { { "file_type_tesim" => ["audio"] } }
    let(:sound_asset) { { "file_type_tesim" => ["sound"] } }
    let(:text_asset) { { "file_type_tesim" => ["text"] } }
    let(:image_asset) { { "file_type_tesim" => ["image"] } }
    let(:threed_asset) { { "file_type_tesim" => ["3d"] } }

    it "picks the video asset for VIDEO" do
      expect(described_class.mainfile_for_type("VIDEO", [text_asset, video_asset])).to eq(video_asset)
    end

    it "picks an 'audio' asset for SOUND" do
      expect(described_class.mainfile_for_type("SOUND", [text_asset, audio_asset])).to eq(audio_asset)
    end

    it "picks a 'sound' asset for SOUND when there is no 'audio' asset (previously broken)" do
      expect(described_class.mainfile_for_type("SOUND", [text_asset, sound_asset])).to eq(sound_asset)
    end

    it "returns nil for SOUND when neither audio nor sound assets exist" do
      expect(described_class.mainfile_for_type("SOUND", [text_asset, image_asset])).to be_nil
    end

    it "picks the text asset for TEXT when iiif is not the main display" do
      expect(described_class.mainfile_for_type("TEXT", [image_asset, text_asset], false)).to eq(text_asset)
    end

    it "falls back to an image asset for TEXT when there is no text asset" do
      expect(described_class.mainfile_for_type("TEXT", [image_asset], false)).to eq(image_asset)
    end

    it "picks the image asset for TEXT when iiif is configured as the main display" do
      expect(described_class.mainfile_for_type("TEXT", [text_asset, image_asset], true)).to eq(image_asset)
    end

    it "picks the image asset for IMAGE" do
      expect(described_class.mainfile_for_type("IMAGE", [text_asset, image_asset])).to eq(image_asset)
    end

    it "picks the 3d asset for 3D" do
      expect(described_class.mainfile_for_type("3D", [text_asset, threed_asset])).to eq(threed_asset)
    end

    it "returns nil for an unrecognised edm type" do
      expect(described_class.mainfile_for_type("INVALID", [text_asset])).to be_nil
    end
  end
end
