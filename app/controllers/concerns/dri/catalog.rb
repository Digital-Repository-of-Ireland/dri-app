require 'iso8601'
require 'iso-639'

module DRI::Catalog
  extend ActiveSupport::Concern

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Hydra::AccessControlsEnforcement
  include DRI::Readable

  MAX_TIMELINE_ENTRIES = 50
  TIMELINE_FIELD_LABELS = {
    'sdate' => 'Subject (Temporal)',
    'cdate' => 'Creation Date',
    'pdate' => 'Publication Date',
    'date' => 'Date'
  }

  included do
    # need rescue_from here to ensure that errors thrown by before_action
    # below are caught and handled properly
    rescue_from Blacklight::Exceptions::InvalidSolrID, with: :render_404
    # These before_filters apply the hydra access controls
    before_action :enforce_search_for_show_permissions, only: :show
  end

  private

    # This method shows the DO if the metadata is open
    # rather than before where the user had to have read permissions on the object all the time
    def enforce_search_for_show_permissions
      enforce_permissions!("show_digital_object", params[:id])
    end

    def configure_timeline(solr_parameters, user_parameters)
      if user_parameters[:view] == 'timeline'
        tl_field = user_parameters[:tl_field].presence || 'sdate'
        case tl_field
        when 'cdate'
          solr_parameters[:fq] << "+cdateRange:*"
          solr_parameters[:fq] << "+cdate_range_start_isi:[* TO *]"
          solr_parameters[:sort] = "cdate_range_start_isi asc"
        when 'pdate'
          solr_parameters[:fq] << "+pdateRange:*"
          solr_parameters[:fq] << "+pdate_range_start_isi:[* TO *]"
          solr_parameters[:sort] = "pdate_range_start_isi asc"
        when 'sdate'
          solr_parameters[:fq] << "+sdateRange:*"
          solr_parameters[:fq] << "+sdate_range_start_isi:[* TO *]"
          solr_parameters[:sort] = "sdate_range_start_isi asc"
        when 'date'
          solr_parameters[:fq] << "+ddateRange:*"
          solr_parameters[:fq] << "+date_range_start_isi:[* TO *]"
          solr_parameters[:sort] = "date_range_start_isi asc"
        end

        solr_parameters[:rows] = MAX_TIMELINE_ENTRIES
        solr_parameters[:start] = if params[:tl_page].present? && params[:tl_page].to_i > 1
                                    MAX_TIMELINE_ENTRIES * (params[:tl_page].to_i - 1)
                                  else
                                    0
                                  end
      else
        params.delete(:tl_page)
        params.delete(:tl_field)
      end
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
