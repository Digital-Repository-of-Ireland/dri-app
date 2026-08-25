# frozen_string_literal: true

module DRI
  module Formatters
    class OpenAire < OAI::Provider::Metadata::Format
      # Resolves the value used for datacite:date[@dateType=Issued]:
      # prefers a parsed "start" date out of published_date_tesim (which
      # may be a date range string), falling back to the record's
      # published_at timestamp when that's absent.
      class PublishedDateResolver
        def self.resolve(record)
          if record.key?("published_date_tesim") && record["published_date_tesim"].present?
            parsed = DRI::Metadata::Transformations.date_range(record["published_date_tesim"].first)
            return parsed["start"] if parsed.key?("start")
          end

          parse_published_at(record)
        end

        def self.parse_published_at(record)
          DateTime.parse(record["published_at_dttsi"]).strftime("%Y-%m-%d")
        end
      end
    end
  end
end
