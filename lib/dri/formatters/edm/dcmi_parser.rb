# frozen_string_literal: true

module DRI
  module Formatters
    class Edm
      # Parses DCMI Box/Period style strings, e.g.
      #   "name=Some Place; north=53.3; east=-6.2"
      #   "name=1916; start=1916-04-24; end=1916-04-30"
      # into a plain hash, and answers whether the result looks like a
      # valid period (has name + start) or a valid point (has name + lat/long).
      class DcmiParser
        def self.parse(value)
          new(value).components
        end

        def self.valid_period?(components)
          components["name"].present? && components["start"].present?
        end

        def self.valid_point?(components)
          components["name"].present? && components["north"].present? && components["east"].present?
        end

        def initialize(value)
          @value = value.to_s
        end

        def components
          return {} if @value.blank?

          @value.split(/\s*;\s*/).each_with_object({}) do |component, hash|
            key, val = component.split(/\s*=\s*/)
            next if key.nil?

            hash[key.downcase] = val.strip if val.present?
          end
        end
      end
    end
  end
end
