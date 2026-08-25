require 'iso8601'
require 'iso-639'
require 'rsolr'

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

  def load_search_results
    @response      = search_service.search_results
    @document_list = @response.documents
  end

  def fetch_and_validate_document
    document = search_service.fetch(params[:id])
    raise DRI::Exceptions::BadRequest, "Invalid object type DRI::GenericFile" if document.generic_file?
    document
  end

  def load_collection_titles
    @collection_titles = Rails.cache.fetch('root_collection_titles', expires_in: 12.hours) do
      super
    end
  end

  def load_timeline_data_if_needed
    @available_timelines = available_timelines_from_facets
    @timeline_data = timeline_data if timeline_view?
  end

  def load_document_type_data
    @document.collection? ? load_collection_data : load_object_data
  end

  def load_object_data
    @assets    = @document.assets(ordered: true)
    @thumbnail = @document.thumbnail
  end

  def load_doi_data
    return unless @document.doi

    doi  = DataciteDoi.where(object_id: @document.id).current
    @doi = doi.doi if doi.present? && doi.minted?
  end

  def render_formatted(formatter_class, fmt, plain: false)
    formatter = formatter_class.new(self, @document, formatter_options)
    plain ? render(plain: formatter.format({ format: fmt })) : render(json: formatter.format(func: fmt))
  end

  def formatter_options
    {}.tap { |opts| opts[:with_assets] = true if can?(:read, @document) }
  end

  def timeline_view?
    params[:view].present? && params[:view].include?('timeline')
  end

  # override this method to change the JSON response from #index
  def render_search_results_as_json
    @presenter = Blacklight::JsonPresenter.new(@response, blacklight_config)
    { response: { docs: @document_list, facets: @presenter.search_facets, pages: @presenter.pagination_info } }
  end

  def show_organisations
    @should_render_depositing_organization = should_render_depositing_organization?(@document)
  end

  private

  def should_render_depositing_organization?(document)
    !document.dataset?
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

  def root_collection_filter
    [
      "+is_collection_ssi:true",
      "-ancestor_id_ssim:[* TO *]"
    ]
  end

  def load_collection_titles
    solr_query = Solr::Query.new(
      "*:*",
      100,
      { fq: root_collection_filter, fl: ['id','title_tesim'] }
    )

    root_collections = {}
    solr_query.each do |entry|
      root_collections[entry['id']] = entry['title_tesim']
    end

    root_collections
  end

  def timeline_data
    tl_field = params[:tl_field].presence || 'sdate'

    timeline = Timeline.new(view_context)
    date_field_events = timeline.data(@document_list, tl_field)

    { available_fields: TIMELINE_FIELD_LABELS.slice(*@available_timelines), field: tl_field, events: date_field_events }
  end
end
