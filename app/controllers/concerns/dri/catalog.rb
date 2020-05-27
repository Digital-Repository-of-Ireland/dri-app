require 'iso8601'
require 'iso-639'
require 'rsolr'
require 'blacklight/catalog'

module DRI::Catalog
  extend ActiveSupport::Concern

  TIMELINE_FIELD_LABELS = {
    'sdate' => 'Subject (Temporal)',
    'cdate' => 'Creation Date',
    'pdate' => 'Publication Date',
    'date' => 'Date'
  }.freeze

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
    include Blacklight::Catalog
    include DRI::Readable

    # need rescue_from here to ensure that errors thrown by before_action
    # below are caught and handled properly
    rescue_from Blacklight::Exceptions::InvalidSolrID, with: :render_404
    # These before_filters apply the hydra access controls
    before_action :enforce_search_for_show_permissions, only: :show
    extend(ClassMethods)
  end

  # override this method to change the JSON response from #index
  def render_search_results_as_json
    @presenter = Blacklight::JsonPresenter.new(@response,
                                               @document_list,
                                               facets_from_request,
                                               blacklight_config)

    {response: {docs: @document_list, facets: @presenter.search_facets_as_json, pages: @presenter.pagination_info}}
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
end
