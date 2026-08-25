# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::OpenAire::ResourceTypeMapper do
  def record_with(object_type:, text: false, image: false, video: false, audio: false, threed: false, interactive: false)
    double(
      "record",
      object_type: [object_type],
      text?: text,
      image?: image,
      video?: video,
      audio?: audio,
      threeD?: threed,
      interactive_resource?: interactive
    )
  end

  describe ".for" do
    it "matches text via the text? predicate" do
      record = record_with(object_type: "SomethingElse", text: true)

      result = described_class.for(record)

      expect(result).to eq(resource_type_general: "literature", uri: "http://purl.org/coar/resource_type/c_18cf", label: "text")
    end

    it "matches text via the object_type string when text? is false" do
      record = record_with(object_type: "TEXT")

      result = described_class.for(record)

      expect(result[:label]).to eq("text")
    end

    it "downcases the object_type string before comparing" do
      record = record_with(object_type: "Image")

      expect(described_class.for(record)[:label]).to eq("image")
    end

    it "matches image" do
      record = record_with(object_type: "x", image: true)
      expect(described_class.for(record)[:label]).to eq("image")
    end

    it "matches video" do
      record = record_with(object_type: "x", video: true)
      result = described_class.for(record)
      expect(result[:label]).to eq("video")
      expect(result[:uri]).to eq("http://purl.org/coar/resource_type/c_12ce")
    end

    it "matches sound via the audio? predicate" do
      record = record_with(object_type: "x", audio: true)
      expect(described_class.for(record)[:label]).to eq("sound")
    end

    it "matches sound via the 'sound' object_type string" do
      record = record_with(object_type: "sound")
      expect(described_class.for(record)[:label]).to eq("sound")
    end

    it "matches 3d objects as an interactive resource" do
      record = record_with(object_type: "x", threed: true)

      result = described_class.for(record)

      expect(result).to eq(
        resource_type_general: "dataset", uri: "http://purl.org/coar/resource_type/c_e9a0", label: "interactive resource"
      )
    end

    it "matches interactive_resource? as an interactive resource" do
      record = record_with(object_type: "x", interactive: true)

      result = described_class.for(record)

      expect(result).to eq(
        resource_type_general: "dataset", uri: "http://purl.org/coar/resource_type/c_e9a0", label: "interactive resource"
      )
    end

    it "matches software by object_type string only (no predicate)" do
      record = record_with(object_type: "software")

      result = described_class.for(record)

      expect(result).to eq(resource_type_general: "software", uri: "http://purl.org/coar/resource_type/c_5ce6", label: "software")
    end

    it "matches dataset by object_type string only (no predicate)" do
      record = record_with(object_type: "dataset")

      result = described_class.for(record)

      expect(result).to eq(resource_type_general: "dataset", uri: "http://purl.org/coar/resource_type/c_1843", label: "other")
    end

    it "falls back to 'other research product' for an unrecognised type" do
      record = record_with(object_type: "mystery-type")

      result = described_class.for(record)

      expect(result).to eq(
        resource_type_general: "other research product", uri: "http://purl.org/coar/resource_type/c_1843", label: "other"
      )
    end

    it "gives predicate-true precedence over the object_type string for a different declared type" do
      # object_type says "dataset" but the record predicate says it's actually text -
      # the original if/elsif chain checks predicates first, so text wins.
      record = record_with(object_type: "dataset", text: true)

      expect(described_class.for(record)[:label]).to eq("text")
    end
  end
end
