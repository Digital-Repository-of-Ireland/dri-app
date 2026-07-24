# frozen_string_literal: true

module DRI
  module Formatters
    class OpenAire < OAI::Provider::Metadata::Format
      # Maps a record's visibility onto its COAR access-right URI and
      # label. Any visibility value not listed here (matching the
      # original case/when, which had no else branch) simply has no
      # access rights entry.
      class AccessRightsMapper
        RIGHTS = {
          "public" => { uri: "http://purl.org/coar/access_right/c_abf2", label: "open access" },
          "restricted" => { uri: "http://purl.org/coar/access_right/c_14cb", label: "metadata only access" },
          "logged-in" => { uri: "http://purl.org/coar/access_right/c_16ec", label: "restricted access" }
        }.freeze

        def self.for(visibility)
          RIGHTS[visibility]
        end
      end
    end
  end
end
