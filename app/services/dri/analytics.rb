# frozen_string_literal: true
module DRI
  module Analytics
    ##
    # a completely empty module to include if no parser is configured
    module NullAnalyticsParser; end

    def self.provider_parser
      "DRI::Analytics::#{Settings.analytics.provider.to_s.capitalize}".constantize
    rescue NameError => err
      Rails.logger.warn("Couldn't find an Analytics provider matching "\
                        " #{Settings.analytics.provider}. Loading " \
                        " NullAnalyticsProvider.\n#{err.message}")
      NullAnalyticsParser
    end

    include provider_parser
  end
end