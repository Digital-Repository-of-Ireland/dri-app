# -*- encoding : utf-8 -*-
class MyCollectionsController < ApplicationController
  # authentication must always happen before including DRI::Catalog,
  # otherwise enforce_search_for_show_permissions in catalog will return 401
  # even when the user provides a valid api key
  before_action :authenticate_user_from_token!
  include DRI::Catalog
  include DRI::MyCollectionsSearchExtension
  before_action :authenticate_user!

  configure_blacklight do |config|

    config.advanced_search = {
      query_parser: 'edismax',
      url_key: 'advanced'
    }

    config.search_builder_class = ::MyCollectionsSearchBuilder

    config.show.route = { controller: 'my_collections' }
    config.per_page = [12, 24, 36, 48, 72, 96]
    config.default_per_page = 12

    config.default_solr_params = {
      defType: 'edismax',
      qt: 'search',
      rows: 9
    }

    # solr field configuration for search results/index views
    config.index.title_field = solr_name('title', :stored_searchable, type: :string)
    config.index.record_tsim_type = solr_name('has_model', :stored_searchable, type: :symbol)

    # solr field configuration for document/show views
    config.show.title_field = solr_name('title', :stored_searchable, type: :string)
    config.show.display_type_field = solr_name('file_type', :stored_searchable, type: :string)

    config.show.document_actions.delete(:email)
    config.show.document_actions.delete(:sms)
    config.show.document_actions.delete(:citation)

    # solr fields that will be treated as facets by the blacklight application
    # The ordering of the field names is the order of the display
    config.add_facet_field 'cdate_range_start_isi', show: false
    config.add_facet_field 'sdate_range_start_isi', show: false
    config.add_facet_field 'pdate_range_start_isi', show: false
    config.add_facet_field 'date_range_start_isi', show: false

    config.add_facet_field solr_name('licence', :facetable), label: 'Licence', limit: 20
    config.add_facet_field solr_name('status', :facetable), label: 'Record Status'
    config.add_facet_field solr_name('master_file_access', :facetable), label: 'Master File Access'
    config.add_facet_field solr_name('subject', :facetable), limit: 20
    config.add_facet_field solr_name('subject_gle', :facetable), label: 'Subjects (in Irish)'
    config.add_facet_field solr_name('subject_eng', :facetable), label: 'Subjects (in English)'
    config.add_facet_field solr_name('geographical_coverage', :facetable), helper_method: :parse_location, show: false
    config.add_facet_field solr_name('placename_field', :facetable), limit: 20
    config.add_facet_field solr_name('geographical_coverage_gle', :facetable), label: 'Subject (Place) (in Irish)', limit: 20
    config.add_facet_field solr_name('geographical_coverage_eng', :facetable), label: 'Subject (Place) (in English)', limit: 20
    config.add_facet_field solr_name('temporal_coverage', :facetable), helper_method: :parse_era, limit: 20
    config.add_facet_field solr_name('temporal_coverage_gle', :facetable), label: 'Subject (Era) (in Irish)', limit: 20
    config.add_facet_field solr_name('temporal_coverage_eng', :facetable), label: 'Subject (Era) (in English)', limit: 20
    config.add_facet_field solr_name('name_coverage', :facetable), label: 'Subject (Name)', limit: 20
    config.add_facet_field solr_name('creator', :facetable), label: 'creators', show: false
    config.add_facet_field solr_name('contributor', :facetable), label: 'contributors', show: false
    config.add_facet_field solr_name('person', :facetable), limit: 20, helper_method: :parse_orcid
    config.add_facet_field solr_name('language', :facetable), helper_method: :label_language, limit: true
    config.add_facet_field solr_name('creation_date', :dateable), label: 'Creation Date', date: true
    config.add_facet_field solr_name('published_date', :dateable), label: 'Published/Broadcast Date', date: true
    config.add_facet_field solr_name('width', :facetable, type: :integer), label: 'Image Width'
    config.add_facet_field solr_name('height', :facetable, type: :integer), label: 'Image Height'
    config.add_facet_field solr_name('area', :facetable, type: :integer), label: 'Image Size'

    config.add_facet_field solr_name('geojson', :symbol), limit: -2, label: 'Coordinates', show: false

    # duration is measured in milliseconds
    config.add_facet_field solr_name('duration_total', :stored_sortable, type: :integer), label: 'Total Duration'

    config.add_facet_field solr_name('channels', :facetable, type: :integer), label: 'Audio Channels'
    config.add_facet_field solr_name('sample_rate', :facetable, type: :integer), label: 'Sample Rate'
    config.add_facet_field solr_name('bit_depth', :facetable, type: :integer), label: 'Bit Depth'
    config.add_facet_field solr_name('file_count', :stored_sortable, type: :integer), label: 'Number of Files'
    config.add_facet_field solr_name('file_size_total', :stored_sortable, type: :integer), label: 'Total File Size'
    config.add_facet_field solr_name('mime_type', :facetable), label: 'MIME Type'
    config.add_facet_field solr_name('file_format', :facetable), label: 'File Format'
    config.add_facet_field solr_name('file_type_display', :facetable)
    config.add_facet_field solr_name('object_type', :facetable), label: 'Type (from Metadata)'
    config.add_facet_field solr_name('depositor', :facetable), label: 'Depositor'
    config.add_facet_field solr_name('institute', :facetable)
    config.add_facet_field solr_name('root_collection_id', :facetable), helper_method: :collection_title

    config.add_facet_field solr_name('is_collection', :facetable), label: 'is_collection', helper_method: :is_collection, show: false

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys

    # solr fields to be displayed in the index (search results) view
    # The ordering of the field names is the order of the display
    config.add_index_field solr_name('title', :stored_searchable, type: :string), label: 'title'
    config.add_index_field solr_name('subject', :stored_searchable, type: :string), label: 'subjects'
    config.add_index_field solr_name('creator', :stored_searchable, type: :string), label: 'creators'
    config.add_index_field solr_name('format', :stored_searchable), label: 'format'
    config.add_index_field solr_name('file_type_display', :stored_searchable, type: :string), label: 'Mediatype'
    config.add_index_field solr_name('language', :stored_searchable, type: :string), label: 'language', helper_method: :label_language
    config.add_index_field solr_name('published', :stored_searchable, type: :string), label: 'Published:'

    # solr fields to be displayed in the show (single result) view
    # The ordering of the field names is the order of the display
    config.add_show_field solr_name('title', :stored_searchable, type: :string), label: 'title'
    config.add_show_field solr_name('subtitle', :stored_searchable, type: :string), label: 'subtitle:'
    config.add_show_field solr_name('description', :stored_searchable, type: :string), label: 'description', helper_method: :render_description
    config.add_show_field solr_name('description_gle', :stored_searchable, type: :string), label: 'description_gle', helper_method: :render_description
    config.add_show_field solr_name('description_eng', :stored_searchable, type: :string), label: 'description_eng', helper_method: :render_description
    config.add_show_field solr_name('creator', :stored_searchable, type: :string), label: 'creators', helper_method: :parse_orcid
    DRI::Vocabulary.marc_relators.each do |role|
      config.add_show_field solr_name('role_' + role, :stored_searchable, type: :string), label: 'role_' + role, helper_method: :parse_orcid
    end
    config.add_show_field solr_name('contributor', :stored_searchable, type: :string), label: 'contributors', helper_method: :parse_orcid
    config.add_show_field solr_name('creation_date', :stored_searchable), label: 'creation_date', date: true, helper_method: :parse_era
    config.add_show_field solr_name('publisher', :stored_searchable), label: 'publishers'
    config.add_show_field solr_name('published_date', :stored_searchable), label: 'published_date', date: true, helper_method: :parse_era
    config.add_show_field solr_name('date', :stored_searchable), label: 'date', date: true, helper_method: :parse_era
    config.add_show_field solr_name('subject', :stored_searchable, type: :string), label: 'subjects'
    config.add_show_field solr_name('geographical_coverage', :stored_searchable, type: :string), label: 'geographical_coverage'
    config.add_show_field solr_name('temporal_coverage', :stored_searchable, type: :string), label: 'temporal_coverage'
    config.add_show_field solr_name('name_coverage', :stored_searchable, type: :string), label: 'name_coverage'
    config.add_show_field solr_name('format', :stored_searchable), label: 'format'
    config.add_show_field solr_name('type', :stored_searchable, type: :string), label: 'type'
    config.add_show_field solr_name('language', :stored_searchable, type: :string), label: 'language', helper_method: :label_language
    config.add_show_field solr_name('source', :stored_searchable, type: :string), label: 'sources'
    config.add_show_field solr_name('rights', :stored_searchable, type: :string), label: 'rights'
    config.add_show_field solr_name('properties_status', :stored_searchable, type: :string), label: 'status'

    config.add_search_field 'all_fields', label: 'All Fields'
    config.dri_display_search_fields = %i[all_fields title subject person place]
    config.dri_all_search_fields = %i[
      title subject description creator contributor publisher person place
    ]

    config.dri_all_search_fields.each do |field_name|
      config.add_search_field(field_name) do |field|
        field.solr_local_parameters = {
          qf: "$#{field_name}_qf",
          pf: "$#{field_name}_pf"
        }
        field.label = self.solr_field_to_label(field_name)
      end
    end

    # "sort results by" select (pulldown)
    config.add_sort_field "system_create_dtsi desc", label: "date created \u25BC"
    config.add_sort_field "system_create_dtsi asc", label: "date created \u25B2"
    config.add_sort_field "system_modified_dtsi desc", label: "date modified \u25BC"
    config.add_sort_field "system_modified_dtsi asc", label: "date modified \u25B2"
    config.add_sort_field "score desc, system_modified_dtsi desc", label: "relevance \u25BC"
    config.add_sort_field "title_sorted_ssi asc", label: "title (A-Z)"
    config.add_sort_field "title_sorted_ssi desc", label: "title (Z-A)"
    config.add_sort_field 'id_asset_ssi asc, system_create_dtsi desc', label: 'order/sequence'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    config.view.maps.coordinates_field = 'geospatial'
    config.view.maps.placename_property = 'placename'
    config.view.maps.tileurl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
    config.view.maps.mapattribution = 'Map data &copy; <a href="https://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>'
    config.view.maps.maxzoom = 18
    config.view.maps.show_initial_zoom = 5
    config.view.maps.facet_mode = 'geojson'
    config.view.maps.placename_field = ActiveFedora.index_field_mapper.solr_name('placename_field', :facetable, type: :string)
    config.view.maps.geojson_field = ActiveFedora.index_field_mapper.solr_name('geojson', :stored_searchable, type: :symbol)
    config.view.maps.search_mode = 'coordinates'
    config.view.maps.spatial_query_dist = 0.5
  end

  def self.controller_path
    'my_collections'
  end

  def index
    params[:q] = params.delete(:q_ws)
    (@response, @document_list) = search_results(params)

    @available_timelines = available_timelines_from_facets
    if params[:view].present? && params[:view].include?('timeline')
      @timeline_data = timeline_data
    end

    params[:q_ws] = params.delete(:q)

    respond_to do |format|
      format.html { store_preferred_view }
      format.rss  { render layout: false }
      format.atom { render layout: false }
      format.json { render json: render_search_results_as_json }

      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  # get a single document from the index
  # to add responses for formats other than html or json see _Blacklight::Document::Export_
  def show
    @response, @document = fetch params[:id]

    # published subcollections unless admin or edit permission
    @children = @document.children(limit: 100).select { |child| child.published? || (current_user.is_admin? || can?(:edit, @document)) }

    # assets including preservation only files, ordered by label
    @assets = @document.assets(with_preservation: true, ordered: true)
    @reader_group = find_reader_group(@document)

    @presenter = DRI::ObjectInMyCollectionsPresenter.new(@document, view_context)

    supported_licences

    respond_to do |format|
      format.html { setup_next_and_previous_documents }
      format.json do
        options = {}
        options[:with_assets] = true if can?(:read, @document)
        formatter = DRI::Formatters::Json.new(self, @document, options)
        render json: formatter.format(func: :as_json)
      end
      format.ttl do
        options = {}
        options[:with_assets] = true if can?(:read, @document)
        formatter = DRI::Formatters::Rdf.new(self, @document, options)
        render plain: formatter.format({format: :ttl})
      end
      format.rdf do
        options = {}
        options[:with_assets] = true if can?(:read, @document)
        formatter = DRI::Formatters::Rdf.new(self, @document, options)
        render plain: formatter.format({format: :xml})
      end
      format.js { render layout: false }

      additional_export_formats(@document, format)
    end
  end

  def duplicates
    enforce_permissions!('manage_collection', params[:id])

    result = ActiveFedora::SolrService.query("id:#{params[:id]}")
    raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') + " ID: #{params[:id]}" if result.blank?

    @object = SolrDocument.new(result.first)

    params[:per_page] ||= blacklight_config.default_per_page
    @response, document_list = @object.duplicates(params[:sort])
    @document_list = Kaminari.paginate_array(document_list).page(params[:page]).per(params[:per_page])
  end

  private

    def find_reader_group(document)
      read_groups = document["#{ActiveFedora.index_field_mapper.solr_name('read_access_group', :stored_searchable, type: :symbol)}"]

      if read_groups.present? && read_groups.include?(document.id)
        UserGroup::Group.find_by(name: document.id)
      end
    end
end
