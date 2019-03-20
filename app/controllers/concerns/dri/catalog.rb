require 'iso8601'
require 'iso-639'
require 'rsolr'

module DRI::Catalog
  extend ActiveSupport::Concern

  #include ::Blacklight::Catalog
  #include Hydra::Controller::ControllerBehavior
  include Hydra::AccessControlsEnforcement
  include ::Hydra::Catalog
  include DRI::Readable

  MAX_TIMELINE_ENTRIES = 50
  TIMELINE_FIELD_LABELS = {
    'sdate' => 'Subject (Temporal)',
    'cdate' => 'Creation Date',
    'pdate' => 'Publication Date',
    'date' => 'Date'
  }.freeze

  EXCLUDE_GENERIC_FILES = "-#{::Solr::SchemaFields.searchable_symbol('has_model')}:\"DRI::GenericFile\"".freeze
  INCLUDE_COLLECTIONS = "+#{::Solr::SchemaFields.facet('is_collection')}:true".freeze
  EXCLUDE_COLLECTIONS = "+#{::Solr::SchemaFields.facet('is_collection')}:false".freeze
  EXCLUDE_SUB_COLLECTIONS = "-#{::Solr::SchemaFields.facet('ancestor_id')}:[* TO *]".freeze
  PUBLISHED_ONLY = "+#{::Solr::SchemaFields.facet('status')}:published".freeze

  module ClassMethods
    # @param [Symbol] solr_field
    # @return [String]
    def solr_field_to_label(solr_field)
      field_label_mappings = {
        title: 'Titles', subject: 'Subjects', description: 'Descriptions',
        creator: 'Creators', contributor: 'Contributors', publisher: 'Publishers',
        person: 'Names', place: 'Places'
      }
      field_label_mappings[solr_field]
    end
  end

  included do
    # need rescue_from here to ensure that errors thrown by before_action
    # below are caught and handled properly
    rescue_from Blacklight::Exceptions::InvalidSolrID, with: :render_404
    # These before_filters apply the hydra access controls
    before_action :enforce_search_for_show_permissions, only: :show
    extend(ClassMethods)
  end


  private

    # This method shows the DO if the metadata is open
    # rather than before where the user had to have read permissions on the object all the time
    def enforce_search_for_show_permissions
      enforce_permissions!("show_digital_object", params[:id])
    end

    def available_timelines_from_facets
      available_timelines = []
      TIMELINE_FIELD_LABELS.keys.each do |field|
        if @response['facet_counts']['facet_fields']["#{field}_range_start_isi"].present?
          available_timelines << field
        end
      end

      available_timelines
    end

    def timeline_data
      tl_field = params[:tl_field].presence || 'sdate'

      timeline = Timeline.new(view_context)
      date_field_events = timeline.data(@document_list, tl_field)

      { available_fields: TIMELINE_FIELD_LABELS.slice(*@available_timelines), field: tl_field, events: date_field_events }
    end

    # If querying geographical_coverage, then query the Solr geospatial field
    #
    def subject_place_filter(solr_parameters, user_parameters)
      # Find index of the facet geographical_coverage_sim
      geographical_idx = nil
      solr_parameters[:fq].each.with_index do |f_elem, idx|
        geographical_idx = idx if f_elem.include?('geographical_coverage')
      end

      unless geographical_idx.nil?
        geo_string = solr_parameters[:fq][geographical_idx]
        coordinates = DRI::Metadata::Transformations.get_spatial_coordinates(geo_string)

        if coordinates.present?
          solr_parameters[:fq][geographical_idx] = "geospatial:\"Intersects(#{coordinates})\""
        end
      end
    end
end
