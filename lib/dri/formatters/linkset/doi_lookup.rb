# frozen_string_literal: true

module DRI
  module Formatters
    class Linkset
      # Resolves the minted DOI (if any) for a document.
      class DoiLookup
        def self.resolve(document)
          doi = DataciteDoi.where(object_id: document.id).current
          return nil unless doi.present? && doi.minted?

          doi.doi
        end
      end
    end
  end
end
