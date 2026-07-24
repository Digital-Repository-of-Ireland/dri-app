# frozen_string_literal: true

module DRI
  module Formatters
    class OpenAire < OAI::Provider::Metadata::Format
      # Looks up the (unfiltered by mint-status) DataciteDoi record for a
      # document, if any.
      class DoiFinder
        def self.find(record)
          DataciteDoi.find_by(object_id: record.id)
        end
      end
    end
  end
end
