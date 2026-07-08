# frozen_string_literal: true

module DRI
  module Formatters
    class Linkset
      # Extracts ORCID profile URLs from a document's contributor_tesim
      # field.
      class ContributorLinks
        # ORCID iDs have a fixed shape: four groups of four digits, the
        # last of which may end in a checksum "X" (e.g.
        # 0000-0001-2345-6789 or 0000-0001-2345-678X). Matching that
        # precise shape - rather than a greedy `\S+` - means trailing
        # punctuation right after the URL (a closing parenthesis, a
        # comma, etc.) is never swept into the match.
        ORCID_PATTERN = %r{https://orcid\.org/\d{4}-\d{4}-\d{4}-\d{3}[0-9X]}.freeze

        def self.for(document)
          return nil unless document["contributor_tesim"].present?

          document["contributor_tesim"].map { |entry| entry[ORCID_PATTERN] }.compact
        end
      end
    end
  end
end