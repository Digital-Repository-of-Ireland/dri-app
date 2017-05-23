module DRI
  module Solr
    module Document
      module Metadata
        DEFAULT_METADATA_FIELDS = ['title', 'subject', 'creation_date', 'published_date',
                                   'type', 'rights', 'language', 'description', 'creator',
                                   'contributor', 'publisher', 'date', 'format', 'source', 'temporal_coverage',
                                   'geographical_coverage', 'geocode_point', 'geocode_box', 'institute',
                                   'root_collection_id', 'isGovernedBy', 'ancestor_id', 'ancestor_title', 'role_dnr'].freeze

        def metadata(field)
          self[ActiveFedora.index_field_mapper.solr_name(field, :stored_searchable)]
        end

        def title
          metadata('title')
        end

        def description
          metadata('description')
        end

        def creator
          metadata('creator')
        end

        def creation_date
          metadata('creation_date')
        end

        def identifier
          profile = JSON.parse(self['object_profile_ssm'].first)

          id = profile['identifier'].presence
        end

        def published_date
          metadata('published_date')
        end

        def date
          metadata('date')
        end

        def rights
          metadata('rights')
        end

        def extract_metadata(metadata_fields)
          item = {}

          # Get metadata
          item['pid'] = id
          item['metadata'] = {}

          fields = metadata_fields || DEFAULT_METADATA_FIELDS

          fields.each do |field|
            value = if field == 'isGovernedBy'
                      self[ActiveFedora.index_field_mapper.solr_name(field, :stored_searchable, type: :symbol)]
                    else
                      self[ActiveFedora.index_field_mapper.solr_name(field, :stored_searchable)]
                    end

            case field
            when 'institute'
              item['metadata'][field] = institutes

            when 'geocode_point'
              if value.present?
                geojson_points = []
                value.each { |point| geojson_points << dcterms_point_to_geojson(point) }

                item['metadata'][field] = geojson_points
              end

            when 'geocode_box'
              if value.present?
                geojson_boxes = []
                value.each { |box| geojson_boxes << dcterms_box_to_geojson(box) }

                item['metadata'][field] = geojson_boxes
              end

            when field.include?('date') || field == 'temporal_coverage'
              if value.present?
                dates = []
                value.each { |d| dates << dcterms_period_to_string(d) }

                item['metadata'][field] = dates
              end

            else
              item['metadata'][field] = value if value
            end
          end
          
          item
        end

        def dcterms_point_to_geojson(point)
          return nil if point.blank?
          point_hash = {}

          point.split(/\s*;\s*/).each do |component|
            (key, value) = component.split(/\s*=\s*/)
            point_hash[key] = value
          end

          return nil unless point_hash.keys.include?('name')

          tmp_hash = {}
          geojson_hash = {}
          geojson_hash[:type] = 'Feature'
          geojson_hash[:geometry] = {}

          coords = [Float(point_hash['east']), Float(point_hash['north'])]
          tmp_hash[:name] = point_hash['name']

          geojson_hash[:geometry][:type] = 'Point'
          geojson_hash[:geometry][:coordinates] = coords
          geojson_hash[:properties] = tmp_hash

          geojson_hash
        end

        def dcterms_box_to_geojson(box)
          return nil if box.blank?
          point_hash = {}

          box.split(/\s*;\s*/).each do |component|
            (key, value) = component.split(/\s*=\s*/)
            point_hash[key] = value
          end

          return nil unless point_hash.keys.include?('name')

          tmp_hash = {}
          geojson_hash = {}
          geojson_hash[:type] = 'Feature'
          geojson_hash[:geometry] = {}

          coords = [[
            [Float(point_hash['westlimit']), Float(point_hash['northlimit'])],
            [Float(point_hash['westlimit']), Float(point_hash['southlimit'])],
            [Float(point_hash['eastlimit']), Float(point_hash['southlimit'])],
            [Float(point_hash['eastlimit']), Float(point_hash['northlimit'])]
          ]]
          tmp_hash[:name] = point_hash['name']

          geojson_hash[:geometry][:type] = 'Polygon'
          geojson_hash[:geometry][:coordinates] = coords
          geojson_hash[:properties] = tmp_hash

          geojson_hash
        end

        def dcterms_period_to_string(period)
          return nil if period.nil? || period.blank?

          period.split(/\s*;\s*/).each do |component|
            (k,v) = component.split(/\s*=\s*/)
            if k.eql?('name')
              return v unless v.nil? || v.empty?
            end
          end
          
          period
        end
      end
    end
  end
end
