# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Formatters::Edm::TranscribathonEnricher do
  let(:record) { double("record", id: "abc123") }
  let(:xml) { Builder::XmlMarkup.new }

  subject(:enricher) { described_class.new(record) }

  def story_double(items: [], people: [], places: [])
    double("TpStory", items: items, people: people, places: places)
  end

  describe "#present?" do
    it "is false when there is no matching TpStory" do
      allow(TpStory).to receive_message_chain(:where, :first).and_return(nil)

      expect(enricher.present?).to be false
    end

    it "is true when a matching TpStory exists" do
      allow(TpStory).to receive_message_chain(:where, :first).and_return(story_double)

      expect(enricher.present?).to be true
    end
  end

  describe "#write" do
    it "does nothing when there is no TpStory" do
      allow(TpStory).to receive_message_chain(:where, :first).and_return(nil)

      enricher.write(xml)

      expect(xml.target!).to eq("")
    end

    context "dates" do
      it "writes a dc:date per unique start/end pair and records it for later use as a contextual class" do
        item1 = double("item", start_date: "1916-04-24", end_date: "1916-04-30")
        item2 = double("item", start_date: "1916-04-24", end_date: "1916-04-30") # duplicate
        story = story_double(items: [item1, item2])
        allow(TpStory).to receive_message_chain(:where, :first).and_return(story)

        enricher.write(xml)

        expect(xml.target!.scan("<dc:date").size).to eq(1)
        expect(xml.target!).to include('edm:wasGeneratedBy="Person"')
        expect(xml.target!).to include("1916-04-24 - 1916-04-30")
        expect(enricher.dates).to eq(
          "1916-04-24 - 1916-04-30" => { "start" => "1916-04-24", "end" => "1916-04-30" }
        )
      end

      it "skips items with neither a start nor end date" do
        item = double("item", start_date: nil, end_date: nil)
        story = story_double(items: [item])
        allow(TpStory).to receive_message_chain(:where, :first).and_return(story)

        enricher.write(xml)

        expect(xml.target!).not_to include("<dc:date")
      end

      it "falls back to end_date when start_date is missing, and vice versa" do
        item = double("item", start_date: nil, end_date: "1916-04-30")
        story = story_double(items: [item])
        allow(TpStory).to receive_message_chain(:where, :first).and_return(story)

        enricher.write(xml)

        expect(enricher.dates["1916-04-30"]).to eq("start" => "1916-04-30", "end" => "1916-04-30")
      end
    end

    context "people" do
      it "writes a dc:subject combining name, dates and description" do
        person = double(
          "person",
          last_name: "Pearse", first_name: "Patrick",
          birth_date: "1879", death_date: "1916",
          person_description: "Educator and revolutionary"
        )
        story = story_double(people: [person])
        allow(TpStory).to receive_message_chain(:where, :first).and_return(story)

        enricher.write(xml)

        expect(xml.target!).to include("Pearse, Patrick, 1879 - 1916 (Educator and revolutionary)")
      end

      it "does not append an empty description when person_description is blank" do
        person = double(
          "person",
          last_name: "Pearse", first_name: "Patrick",
          birth_date: nil, death_date: nil,
          person_description: nil
        )
        story = story_double(people: [person])
        allow(TpStory).to receive_message_chain(:where, :first).and_return(story)

        enricher.write(xml)

        expect(xml.target!).to include("Pearse, Patrick")
        expect(xml.target!).not_to include("()")
      end

      it "does not append an empty description when person_description is the literal string NULL" do
        person = double(
          "person",
          last_name: "Pearse", first_name: "Patrick",
          birth_date: nil, death_date: nil,
          person_description: "NULL"
        )
        story = story_double(people: [person])
        allow(TpStory).to receive_message_chain(:where, :first).and_return(story)

        enricher.write(xml)

        expect(xml.target!).not_to include("()")
      end

      it "deduplicates identical people entries" do
        person1 = double("person", last_name: "Pearse", first_name: "Patrick", birth_date: nil, death_date: nil, person_description: nil)
        person2 = double("person", last_name: "Pearse", first_name: "Patrick", birth_date: nil, death_date: nil, person_description: nil)
        story = story_double(people: [person1, person2])
        allow(TpStory).to receive_message_chain(:where, :first).and_return(story)

        enricher.write(xml)

        expect(xml.target!.scan("<dc:subject").size).to eq(1)
      end
    end

    context "places" do
      it "writes a dcterms:spatial resource reference and records lat/long when present" do
        place = double("place", place_name: "Dublin", latitude: "53.3", longitude: "-6.2", wikidata_id: nil)
        story = story_double(places: [place])
        allow(TpStory).to receive_message_chain(:where, :first).and_return(story)

        enricher.write(xml)

        expect(xml.target!).to include('rdf:resource="#Dublin"')
        expect(enricher.places).to eq([["Dublin", "53.3", "-6.2"]])
      end

      it "writes a wikidata-based resource reference when there is no lat/long but a wikidata id" do
        allow(Settings).to receive_message_chain(:transcribathon, :wikidata_endpoint).and_return("https://www.wikidata.org/wiki/")
        place = double("place", place_name: nil, latitude: nil, longitude: nil, wikidata_id: "Q1761")
        story = story_double(places: [place])
        allow(TpStory).to receive_message_chain(:where, :first).and_return(story)

        enricher.write(xml)

        expect(xml.target!).to include('rdf:resource="https://www.wikidata.org/wiki/Q1761"')
      end

      it "writes a plain-text place name when there is neither lat/long nor a wikidata id" do
        place = double("place", place_name: "Dublin", latitude: nil, longitude: nil, wikidata_id: nil)
        story = story_double(places: [place])
        allow(TpStory).to receive_message_chain(:where, :first).and_return(story)

        enricher.write(xml)

        expect(xml.target!).to include("Dublin")
        expect(xml.target!).not_to include("rdf:resource")
      end

      it "does not double-record the same lat/long place twice" do
        place1 = double("place", place_name: "Dublin", latitude: "53.3", longitude: "-6.2", wikidata_id: nil)
        place2 = double("place", place_name: "Dublin", latitude: "53.3", longitude: "-6.2", wikidata_id: nil)
        story = story_double(places: [place1, place2])
        allow(TpStory).to receive_message_chain(:where, :first).and_return(story)

        enricher.write(xml)

        expect(enricher.places.size).to eq(1)
      end
    end
  end
end
