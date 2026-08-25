# frozen_string_literal: true

module DRI
  module Formatters
    class Linkset
      # Resolves a document's licence URL, if it has one.
      class LicenceLink
        def self.for(document)
          licence = document.licence
          return nil unless licence.present? && licence.respond_to?(:url)

          licence.url
        end
      end
    end
  end
end
