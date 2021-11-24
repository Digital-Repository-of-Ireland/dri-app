# frozen_string_literal: true

# Makes use of some code from
# https://github.com/datacite/bolognese/blob/712184f1c82def2b0c500bb4328bae6b7dc71dee/lib/bolognese/author_utils.rb
module DRI
  module CitationsBehaviours
    module NameBehaviour
      def get_one_author(author, _options = {})
        return { "literal" => "" } if author.strip.blank?

        cleaned_author = cleanup_author(author)
        names = Namae.parse(cleaned_author)
        if names.blank? || personal_name?(cleaned_author).blank?
          { "literal" => author }
        else
          name = names.first

          { "family" => name.family, "given" => name.given }.compact
        end
      end

      def cleanup_author(author)
        # detect pattern "Smith J.", but not "Smith, John K."
        author = author.gsub(/[[:space:]]([A-Z]\.)?(-?[A-Z]\.)$/, ', \1\2') unless author.include?(",")
        # titleize strings
        # remove non-standard space characters
        titleize_name(author).gsub(/[[:space:]]/, " ")
      end

      def personal_name?(author)
        return true if author.include?(",")

        name_parts = author.split

        return false if name_parts.map(&:downcase).intersection(%w[museum archive library and & the ltd co company]).present?
        # lookup given name
        ::NameDetector.name_exists?(name_parts.first) ? true : false
      end

      # parse array of author strings into CSL format
      def get_authors(authors, options = {})
        Array(authors).map { |author| get_one_author(author, options) }
      end

      def titleize_name(string)
        string.gsub(/\b(['’]?[a-z])/) { Regexp.last_match[1].capitalize }
      end
    end
  end
end
