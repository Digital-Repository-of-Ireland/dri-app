# frozen_string_literal: true

module DRI
  module Formatters
    class Edm
      # Writes dc:date / dc:subject / dcterms:spatial elements sourced from
      # a record's associated Transcribathon (TpStory) crowd-sourced data,
      # and collects the user-generated dates/places so the caller can turn
      # them into edm:TimeSpan / edm:Place contextual classes afterwards.
      class TranscribathonEnricher
        attr_reader :dates, :places

        def initialize(record)
          @record = record
          @dates = {}
          @places = []
        end

        def story
          @story ||= TpStory.where(dri_id: @record.id).first
        end

        def present?
          story.present?
        end

        def write(xml)
          return unless present?

          write_dates(xml)
          write_people(xml)
          write_places(xml)
        end

        private

        def write_dates(xml)
          processed = []

          story.items.each do |item|
            next unless item.start_date || item.end_date

            datestring = [item.start_date, item.end_date].reject(&:blank?).join(" - ")
            next if processed.include?(datestring)

            processed << datestring
            xml.tag! "dc:date", { "edm:wasGeneratedBy" => "Person" }, datestring

            dates[datestring] = {
              "start" => item.start_date || item.end_date,
              "end" => item.end_date || item.start_date
            }
          end
        end

        def write_people(xml)
          processed = []

          story.people.each do |person|
            name = [person.last_name, person.first_name].reject { |s| s == "NULL" || s.blank? }.join(", ")
            dates = [person.birth_date, person.death_date].join(" - ") unless person.birth_date.blank? && person.death_date.blank?
            # NOTE: previously `unless i.person_description == "NULL" ||
            # i.person_description == "NULL"` (duplicate, always false unless
            # nil) meant the description was effectively always appended,
            # even when blank. Fixed to also check for blank.
            desc = " (#{person.person_description})" if person.person_description.present? && person.person_description != "NULL"
            namestring = [name, dates].reject(&:blank?).join(", ") + desc.to_s

            next if processed.include?(namestring)

            processed << namestring
            xml.tag! "dc:subject", { "edm:wasGeneratedBy" => "Person", "xml:lang" => "eng" }, namestring
          end
        end

        def write_places(xml)
          story.places.each do |place|
            if place.place_name.present? && place.latitude.present? && place.longitude.present?
              tmp = [place.place_name, place.latitude, place.longitude]
              next if places.include?(tmp)

              places.push(tmp)
              xml.tag! "dcterms:spatial", { "rdf:resource" => "##{place.place_name}", "edm:wasGeneratedBy" => "Person" }
            elsif place.wikidata_id.present?
              url = Settings.transcribathon.wikidata_endpoint + place.wikidata_id.strip
              xml.tag! "dcterms:spatial", { "rdf:resource" => "#{url}", "edm:wasGeneratedBy" => "Person" }
            elsif place.place_name.present?
              xml.tag! "dcterms:spatial", { "edm:wasGeneratedBy" => "Person", "xml:lang" => "eng" }, place.place_name
            end
          end
        end
      end
    end
  end
end
