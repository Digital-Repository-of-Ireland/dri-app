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

  FIELD_LABEL_MAPPINGS = {
        title: 'Titles', subject: 'Subjects', description: 'Descriptions',
        creator: 'Creators', contributor: 'Contributors', publisher: 'Publishers',
        person: 'Names', place: 'Places'
  }.freeze

  module ClassMethods
    # @param [Symbol] solr_field
    # @return [String]
    def solr_field_to_label(solr_field)
      FIELD_LABEL_MAPPINGS[solr_field]
    end
  end

  included do
    include Blacklight::Catalog
    include DRI::Readable

    # need rescue_from here to ensure that errors thrown by before_action
    # below are caught and handled properly
    rescue_from Blacklight::Exceptions::RecordNotFound, with: :render_404
    # These before_filters apply the hydra access controls
    before_action :enforce_search_for_show_permissions, only: :show
    extend(ClassMethods)
  end

  # override this method to change the JSON response from #index
  def render_search_results_as_json
    @presenter = Blacklight::JsonPresenter.new(@response, blacklight_config)
    { response: { docs: @document_list, facets: @presenter.search_facets, pages: @presenter.pagination_info } }
  end

  def show_orgs
    @document = SolrDocument.find(params[:id])
    @should_render_organizations = should_render_organizations?(@document)
  end

  private

  def should_render_organizations?(document)
    dataset = document["dataset_ss"]
    ancestor_id = document["ancestor_id_ssim"]

    if dataset.present?
      return dataset != "Research"
    elsif ancestor_id.present? && ancestor_id != document.id
      ancestor_document = SolrDocument.find(ancestor_id)
      ancestor_dataset = ancestor_document["dataset_ss"] if ancestor_document
      return ancestor_dataset.nil? || ancestor_dataset != "Research"
    end
    true # Default to rendering if no conditions are met
  end

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

    def load_assets_for_document_list
      return {} if @document_list.blank?

      ids_query = Solr::Query.construct_query_for_ids(
                        @document_list.map(&:id),
                        'isPartOf_ssim'
                      )
      fq = ["active_fedora_model_ssi:\"DRI::GenericFile\""]
      fq << "-preservation_only_ssi:true"
      query = Solr::Query.new(ids_query, 100, { fq: fq })
      @assets = {}
      query.each do |file|
        object_id = file['isPartOf_ssim'].first
        files = @assets.key?(object_id) ? @assets[object_id] : []
        files << file
        @assets[object_id] = files
      end
    end

    def load_collection_titles
      return {} if @document_list.blank?
      return unless @response['facet_counts']['facet_fields']['root_collection_id_ssi'].present?
      ids = @response['facet_counts']['facet_fields']['root_collection_id_ssi'].each_slice(2).map(&:first)

      ids_query = Solr::Query.construct_query_for_ids(ids)
      query = Solr::Query.new(ids_query, ids.length)
      @collection_titles = {}
      query.each do |collection|
        @collection_titles[collection.alternate_id] = collection.title
      end
    end

    def timeline_data
      tl_field = params[:tl_field].presence || 'sdate'

      timeline = Timeline.new(view_context)
      date_field_events = timeline.data(@document_list, tl_field)

      { available_fields: TIMELINE_FIELD_LABELS.slice(*@available_timelines), field: tl_field, events: date_field_events }
    end
end
