# frozen_string_literal: true
require "google/analytics/data/v1beta/analytics_data"

module DRI
  module Analytics
    module Ga4
      extend ActiveSupport::Concern
      class_methods do
      	LIMIT = 1000

        def config
          @config ||= Config.load_from_yaml
        end

        class Config
          def self.load_from_yaml
            filename = Rails.root.join('config', 'analytics.yml')
            yaml = YAML.safe_load(ERB.new(File.read(filename)).result)
            unless yaml
              Rails.logger.error("Unable to fetch any keys from #{filename}.")
              return new({})
            end
            config = yaml.fetch('analytics')&.fetch('ga4', nil)
            new config
          end

          KEYS = %w[property_id json_credentials].freeze
          REQUIRED_KEYS = %w[property_id json_credentials].freeze

          def initialize(config)
            @config = config
          end

          # @return [Boolean] are all the required values present?
          def valid?
            REQUIRED_KEYS.all? { |required| @config[required].present? }
          end

          KEYS.each do |key|
            class_eval %{ def #{key}; @config.fetch('#{key}'); end }
            class_eval %{ def #{key}=(value); @config['#{key}'] = value; end }
            KEYS.each do |key|
              class_eval %{ def #{key}; @config.fetch('#{key}'); end }
              class_eval %{ def #{key}=(value); @config['#{key}'] = value; end }
            end
          end
        end

        def auth_client
          json_credentials = config.json_credentials
          raise "Credentials for Google analytics was expected at '#{config.json_credentials}', but no file was found." unless File.exist?(config.json_credentials)
          
          ::Google::Analytics::Data::V1beta::AnalyticsData::Client.new do |client_config|
            client_config.credentials = json_credentials
          end
        end

        def object_events_users(start_date, end_date, collections)
          request = Google::Analytics::Data::V1beta::RunReportRequest.new(
             property: "properties/#{config.property_id}",
             dimensions: [Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:collection'),
                          Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:object'),
                          Google::Analytics::Data::V1beta::Dimension.new(name: 'eventName')
                          ],
             metrics: [
               Google::Analytics::Data::V1beta::Metric.new(
                 name: 'totalUsers',
               )
             ],
             date_ranges: [
               Google::Analytics::Data::V1beta::DateRange.new(
                 start_date: start_date,
                 end_date: end_date
               )
             ],
             dimension_filter: { and_group: {
	                               expressions: [
	                                 { filter: { field_name: "eventName", string_filter: { match_type:  "EXACT", value: "object_view" }}},
	                                 { filter: { field_name: "customEvent:collection", in_list_filter: { values: collections }}}
	                               ]
	                             }
                               },
              keep_empty_rows: false,
              limit: LIMIT
          )

          run_report(request)
        end

        def object_events_hits(start_date, end_date, collections)
          request = Google::Analytics::Data::V1beta::RunReportRequest.new(
             property: "properties/#{config.property_id}",
             dimensions: [Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:collection'),
                          Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:object'),
                          Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:organisation'),
                          Google::Analytics::Data::V1beta::Dimension.new(name: 'eventName')
                          ],
             metrics: [
               Google::Analytics::Data::V1beta::Metric.new(
                 name: 'eventCount',
               )
             ],
             date_ranges: [
               Google::Analytics::Data::V1beta::DateRange.new(
                 start_date: start_date,
                 end_date: end_date
               )
             ],
             dimension_filter: { and_group: {
                                   expressions: [
                                     { filter: { field_name: "eventName", string_filter: { match_type:  "EXACT", value: "object_view" }}},
                                     { filter: { field_name: "customEvent:collection", in_list_filter: { values: collections }}}
                                   ]
                                 }
                               },
              keep_empty_rows: false,
              limit: LIMIT
          )

          run_report(request)
        end

        def object_events_downloads(start_date, end_date, collections)
          request = Google::Analytics::Data::V1beta::RunReportRequest.new(
             property: "properties/#{config.property_id}",
             dimensions: [Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:collection'),
                          Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:object'),
                          Google::Analytics::Data::V1beta::Dimension.new(name: 'eventName')
                          ],
             metrics: [
               Google::Analytics::Data::V1beta::Metric.new(
                 name: 'eventCount',
               )
             ],
             date_ranges: [
               Google::Analytics::Data::V1beta::DateRange.new(
                 start_date: start_date,
                 end_date: end_date
               )
             ],
             dimension_filter: { and_group: {
                                   expressions: [
                                     { filter: { field_name: "eventName", string_filter: { match_type:  "EXACT", value: "asset_download" }}},
                                     { filter: { field_name: "customEvent:collection", in_list_filter: { values: collections }}}
                                   ]
                                 }
                               },
              keep_empty_rows: false,
              limit: LIMIT
          )

          run_report(request)
        end

        def collection_events_users(start_date, end_date, collections)
          request = Google::Analytics::Data::V1beta::RunReportRequest.new(
             property: "properties/#{config.property_id}",
             dimensions: [Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:collection'),
                          Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:object'),
                          Google::Analytics::Data::V1beta::Dimension.new(name: 'eventName')
                          ],
             metrics: [
               Google::Analytics::Data::V1beta::Metric.new(
                 name: 'totalUsers',
               )
             ],
             date_ranges: [
               Google::Analytics::Data::V1beta::DateRange.new(
                 start_date: start_date,
                 end_date: end_date
               )
             ],
             dimension_filter: { and_group: {
                                 expressions: [
                                   { filter: { field_name: "eventName", string_filter: { match_type:  "EXACT", value: "object_view" }}},
                                   { filter: { field_name: "customEvent:object", in_list_filter: { values: collections }}}
                                 ]
                               }
                               },
              keep_empty_rows: false,
              limit: LIMIT
          )

          run_report(request)
        end

        def collection_events_downloads(start_date, end_date, collections)
          request = Google::Analytics::Data::V1beta::RunReportRequest.new(
             property: "properties/#{config.property_id}",
             dimensions: [Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:collection'),
                          Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:object'),
                          Google::Analytics::Data::V1beta::Dimension.new(name: 'eventName')
                          ],
             metrics: [
               Google::Analytics::Data::V1beta::Metric.new(
                 name: 'eventCount',
               )
             ],
             date_ranges: [
               Google::Analytics::Data::V1beta::DateRange.new(
                 start_date: start_date,
                 end_date: end_date
               )
             ],
             dimension_filter: { and_group: {
                                   expressions: [
                                     { filter: { field_name: "eventName", string_filter: { match_type:  "EXACT", value: "asset_download" }}},
                                     { filter: { field_name: "customEvent:object", in_list_filter: { values: collections }}}
                                   ]
                                 }
                               },
              keep_empty_rows: false,
              limit: LIMIT
          )

          run_report(request)
        end

        def run_report(request)
  	      offset = 0
            results = []
            request.offset = 0

  	      loop do
  	        report = auth_client.run_report(request)
  	        
  	        dimension_headers = report.dimension_headers.map(&:name)
  	        metric_headers = report.metric_headers.map(&:name)

  	        report.rows.each do |row|
  	          dimension_values = row.dimension_values.map(&:value)
  	          metric_values = row.metric_values.map(&:value)

  	          result_row = {}
  	          dimension_headers.each_with_index do |header,index|
  	          	result_row[header] = dimension_values[index]
  	          end
                metric_headers.each_with_index do |header,index|
  	          	result_row[header] = metric_values[index]
  	          end

  	          results << result_row
  	        end
  	        break if results.size == report.row_count

  	        offset += LIMIT
  	        request.offset = offset
  	      end

  	      results
        end
      end

    end
  end
end

