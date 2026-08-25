# frozen_string_literal: true

module DRI
  module Formatters
    class Edm
      # Declarative map of edm:ProvidedCHO output fields to the Solr fields
      # (or a computed Proc) they come from. This was previously the
      # ProvidedCHOPREFIXES constant inlined in Edm.
      #
      # NOTE: names are split by lang in names_ fields - how to handle this?
      # NOTE: should we assume other fields not split are therefore English?
      class FieldMapper
        # Given a record, returns the set of values for a field, where value
        # differencing (e.g. "title minus title_eng minus title_gle") is used
        # to recover values that aren't tagged with a specific language.
        def self.language_diff(record, base_field, *lang_fields)
          values = (record[base_field] || []).map(&:strip)
          lang_fields.each do |field|
            values -= (record[field] || []).map(&:strip)
          end
          values
        end

        PREFIXES = {
          dc: {
            title_eng: "title_eng_tesim",
            title_gle: "title_gle_tesim",
            title: lambda do |record|
              FieldMapper.language_diff(record, "title_tesim", "title_eng_tesim", "title_gle_tesim")
            end,
            description_eng: "description_eng_tesim",
            description_gle: "description_gle_tesim",
            description: lambda do |record|
              FieldMapper.language_diff(record, "description_tesim", "description_eng_tesim", "description_gle_tesim")
            end,
            creator: "creator_tesim",
            publisher: "publisher_tesim",
            subject_eng: "subject_eng_tesim",
            subject_gle: "subject_gle_tesim",
            subject: lambda do |record|
              FieldMapper.language_diff(record, "subject_tesim", "subject_eng_tesim", "subject_gle_tesim")
            end,
            type: "type_tesim",
            language: "language_tesim",
            format: "file_type_tesim",
            rights_eng: "rights_eng_tesim",
            rights_gle: "rights_gle_tesim",
            rights: lambda do |record|
              FieldMapper.language_diff(record, "rights_tesim", "rights_eng_tesim", "rights_gle_tesim")
            end,
            source_eng: "source_eng_tesim",
            source_gle: "source_gle_tesim",
            source: lambda do |record|
              FieldMapper.language_diff(record, "source_tesim", "source_eng_tesim", "source_gle_tesim")
            end,
            coverage_eng: "coverage_eng_tesim",
            coverage_gle: "coverage_gle_tesim",
            coverage: lambda do |record|
              FieldMapper.language_diff(record, "coverage_tesim", "coverage_eng_tesim", "coverage_gle_tesim")
            end,
            date: "date_tesim",
            contributor: "person_tesim"
          },
          dcterms: {
            created: "creation_date_tesim",
            issued: "published_date_tesim",
            spatial_eng: "geographical_coverage_eng_tesim",
            spatial_gle: "geographical_coverage_gle_tesim",
            spatial: lambda do |record|
              FieldMapper.language_diff(
                record, "geographical_coverage_tesim",
                "geographical_coverage_eng_tesim", "geographical_coverage_gle_tesim"
              )
            end,
            temporal: "temporal_coverage_tesim"
          },
          edm: {
            type: "object_type_ssm"
          }
        }.freeze

        # Yields [prefix, field_key, source] for every configured field,
        # where source is either a Solr field name (String) or a Proc.
        def self.each_field
          return enum_for(:each_field) unless block_given?

          PREFIXES.each do |prefix, fields|
            fields.each do |key, source|
              yield prefix, key, source
            end
          end
        end

        # Resolves a source (String field name, Array of them, or Proc) into
        # a flat array of values for the given record.
        def self.values_for(source, record)
          return source.call(record) if source.is_a?(Proc)

          Array(source).map { |field| record[field] || [] }.flatten.compact
        end
      end
    end
  end
end
