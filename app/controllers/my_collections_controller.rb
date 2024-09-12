# -*- encoding : utf-8 -*-
class MyCollectionsController < ApplicationController
  # authentication must always happen before including DRI::Catalog,
  # otherwise enforce_search_for_show_permissions in catalog will return 401
  # even when the user provides a valid api key
  before_action :authenticate_user_from_token!
  include DRI::Catalog
  include DRI::MyCollectionsSearchExtension
  before_action :authenticate_user!

  self.search_service_class = ::SearchService

  configure_blacklight do |config|

    config.advanced_search = {
      query_parser: 'edismax',
      url_key: 'advanced'
    }

    #config.document_unique_id_param = 'alternate_id'
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
    config.index.title_field = Solrizer.solr_name('title', :stored_searchable, type: :string)
    config.index.record_tsim_type = Solrizer.solr_name('has_model', :stored_searchable, type: :symbol)

    # solr field configuration for document/show views
    config.show.title_field = Solrizer.solr_name('title', :stored_searchable, type: :string)
    config.show.display_type_field = Solrizer.solr_name('file_type', :stored_searchable, type: :string)

    config.show.document_actions.delete(:email)
    config.show.document_actions.delete(:sms)
    config.show.document_actions.delete(:citation)

    # solr fields that will be treated as facets by the blacklight application
    # The ordering of the field names is the order of the display
    config.add_facet_field 'cdate_range_start_isi', show: false
    config.add_facet_field 'sdate_range_start_isi', show: false
    config.add_facet_field 'pdate_range_start_isi', show: false
    config.add_facet_field 'date_range_start_isi', show: false

    config.add_facet_field Solrizer.solr_name('licence', :facetable), label: 'Licence', limit: 20
    config.add_facet_field Solrizer.solr_name('copyright', :facetable), label: 'Copyright', limit: 20
    config.add_facet_field 'status_ssi', label: 'Record Status'
    config.add_facet_field Solrizer.solr_name('master_file_access', :facetable), label: 'Master File Access'
    config.add_facet_field Solrizer.solr_name('subject', :facetable), limit: 20
    config.add_facet_field Solrizer.solr_name('subject_gle', :facetable), label: 'Subjects (in Irish)'
    config.add_facet_field Solrizer.solr_name('subject_eng', :facetable), label: 'Subjects (in English)'
    config.add_facet_field Solrizer.solr_name('geographical_coverage', :facetable), helper_method: :parse_location, show: false
    config.add_facet_field Solrizer.solr_name('placename_field', :facetable), limit: 20
    config.add_facet_field Solrizer.solr_name('geographical_coverage_gle', :facetable), label: 'Subject (Place) (in Irish)', limit: 20
    config.add_facet_field Solrizer.solr_name('geographical_coverage_eng', :facetable), label: 'Subject (Place) (in English)', limit: 20
    config.add_facet_field Solrizer.solr_name('temporal_coverage', :facetable), helper_method: :parse_era, limit: 20
    config.add_facet_field Solrizer.solr_name('temporal_coverage_gle', :facetable), label: 'Subject (Era) (in Irish)', limit: 20
    config.add_facet_field Solrizer.solr_name('temporal_coverage_eng', :facetable), label: 'Subject (Era) (in English)', limit: 20
    config.add_facet_field Solrizer.solr_name('name_coverage', :facetable), label: 'Subject (Name)', limit: 20
    config.add_facet_field Solrizer.solr_name('creator', :facetable), label: 'creators', show: false
    config.add_facet_field Solrizer.solr_name('contributor', :facetable), label: 'contributors', show: false
    config.add_facet_field Solrizer.solr_name('person', :facetable), limit: 20, helper_method: :parse_orcid
    config.add_facet_field Solrizer.solr_name('language', :facetable), helper_method: :label_language, limit: true
    config.add_facet_field Solrizer.solr_name('creation_date', :dateable), label: 'Creation Date', date: true
    config.add_facet_field Solrizer.solr_name('published_date', :dateable), label: 'Published/Broadcast Date', date: true
    config.add_facet_field Solrizer.solr_name('width', :facetable, type: :integer), label: 'Image Width'
    config.add_facet_field Solrizer.solr_name('height', :facetable, type: :integer), label: 'Image Height'
    config.add_facet_field Solrizer.solr_name('area', :facetable, type: :integer), label: 'Image Size'
    config.add_facet_field Solrizer.solr_name('geojson', :symbol), limit: -2, label: 'Coordinates', show: false
    # duration is measured in milliseconds
    config.add_facet_field Solrizer.solr_name('duration_total', :stored_sortable, type: :integer), label: 'Total Duration'
    config.add_facet_field Solrizer.solr_name('channels', :facetable, type: :integer), label: 'Audio Channels'
    config.add_facet_field Solrizer.solr_name('sample_rate', :facetable, type: :integer), label: 'Sample Rate'
    config.add_facet_field Solrizer.solr_name('bit_depth', :facetable, type: :integer), label: 'Bit Depth'
    config.add_facet_field Solrizer.solr_name('file_count', :stored_sortable, type: :integer), label: 'Number of Files'
    config.add_facet_field Solrizer.solr_name('mime_type', :facetable), label: 'MIME Type'
    config.add_facet_field Solrizer.solr_name('file_format', :facetable), label: 'File Format'
    config.add_facet_field Solrizer.solr_name('file_type_display', :facetable)
    config.add_facet_field Solrizer.solr_name('object_type', :facetable), label: 'Type (from Metadata)'
    config.add_facet_field Solrizer.solr_name('depositor', :facetable)
    config.add_facet_field Solrizer.solr_name('institute', :facetable)
    config.add_facet_field 'root_collection_id_ssi', helper_method: :collection_title, limit: 20
    config.add_facet_field 'ancestor_id_ssim', label: 'ancestor_id', helper_method: :collection_title, show: false
    config.add_facet_field 'is_collection_ssi', label: 'is_collection', helper_method: :is_collection, show: false
    
    config.add_facet_field 'visibility_ssi'

    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    # The ordering of the field names is the order of the display
    config.add_index_field Solrizer.solr_name('title', :stored_searchable, type: :string), label: 'title'
    config.add_index_field Solrizer.solr_name('subject', :stored_searchable, type: :string), label: 'subjects'
    config.add_index_field Solrizer.solr_name('creator', :stored_searchable, type: :string), label: 'creators'
    config.add_index_field Solrizer.solr_name('format', :stored_searchable), label: 'format'
    config.add_index_field Solrizer.solr_name('file_type_display', :stored_searchable, type: :string), label: 'Mediatype'
    config.add_index_field Solrizer.solr_name('language', :stored_searchable, type: :string), label: 'language', helper_method: :label_language
    config.add_index_field Solrizer.solr_name('published', :stored_searchable, type: :string), label: 'Published:'

    # solr fields to be displayed in the show (single result) view
    # The ordering of the field names is the order of the display
    config.add_show_field Solrizer.solr_name('title', :stored_searchable, type: :string), label: 'title'
    config.add_show_field Solrizer.solr_name('subtitle', :stored_searchable, type: :string), label: 'subtitle:'
    config.add_show_field Solrizer.solr_name('description', :stored_searchable, type: :string), label: 'description', helper_method: :render_description
    config.add_show_field Solrizer.solr_name('description_gle', :stored_searchable, type: :string), label: 'description_gle', helper_method: :render_description
    config.add_show_field Solrizer.solr_name('description_eng', :stored_searchable, type: :string), label: 'description_eng', helper_method: :render_description
    config.add_show_field Solrizer.solr_name('creator', :stored_searchable, type: :string), label: 'creators', helper_method: :parse_orcid
    DRI::Vocabulary.marc_relators.each do |role|
      config.add_show_field Solrizer.solr_name('role_' + role, :stored_searchable, type: :string), label: 'role_' + role, helper_method: :parse_orcid
    end
    config.add_show_field Solrizer.solr_name('contributor', :stored_searchable, type: :string), label: 'contributors', helper_method: :parse_orcid
    config.add_show_field Solrizer.solr_name('creation_date', :stored_searchable), label: 'creation_date', date: true, helper_method: :parse_era
    config.add_show_field Solrizer.solr_name('publisher', :stored_searchable), label: 'publishers'
    config.add_show_field Solrizer.solr_name('published_date', :stored_searchable), label: 'published_date', date: true, helper_method: :parse_era
    config.add_show_field Solrizer.solr_name('date', :stored_searchable), label: 'date', date: true, helper_method: :parse_era
    config.add_show_field 'published_at_dttsi', label: 'published_by_dri', date: true, helper_method: :parse_date
    config.add_show_field Solrizer.solr_name('subject', :stored_searchable, type: :string), label: 'subjects'
    config.add_show_field Solrizer.solr_name('geographical_coverage', :stored_searchable, type: :string), label: 'geographical_coverage'
    config.add_show_field Solrizer.solr_name('temporal_coverage', :stored_searchable, type: :string), label: 'temporal_coverage'
    config.add_show_field Solrizer.solr_name('name_coverage', :stored_searchable, type: :string), label: 'name_coverage'
    config.add_show_field Solrizer.solr_name('format', :stored_searchable), label: 'format'
    config.add_show_field Solrizer.solr_name('type', :stored_searchable, type: :string), label: 'type'
    config.add_show_field Solrizer.solr_name('language', :stored_searchable, type: :string), label: 'language', helper_method: :label_language
    config.add_show_field Solrizer.solr_name('source', :stored_searchable, type: :string), label: 'sources'
    config.add_show_field 'identifier_ssim', label: 'identifier'
    config.add_show_field Solrizer.solr_name('rights', :stored_searchable, type: :string), label: 'rights'

    config.add_search_field 'all_fields', label: 'All Fields'
    config.dri_display_search_fields = %i[all_fields title subject person place]
    config.dri_all_search_fields = %i[
      title subject description creator contributor publisher person place
    ]

    config.add_search_field(:title) do |field|
      field.solr_parameters = {
        qf: "title_unstem_search^50000 title_tesim^5000",
        pf: "title_unstem_search^500000 title_tesim^50000"
      }
      field.label = self.solr_field_to_label(:title)
    end
    config.dri_all_search_fields.each do |field_name|
      next if field_name == :title

      config.add_search_field(field_name) do |field|
        field.solr_parameters = {
          qf: "#{field_name}_unstem_search^125 #{field_name}_tesim^50",
          pf: "#{field_name}_unstem_search^1250 #{field_name}_tesim^1000"
        }
        field.label = self.solr_field_to_label(field_name)
      end
    end

    # "sort results by" select (pulldown)
    config.add_sort_field "system_create_dtsi desc", label: "created_desc"
    config.add_sort_field "system_create_dtsi asc", label: "created_asc"
    config.add_sort_field "timestamp desc", label: "timestamp_desc"
    config.add_sort_field "timestamp asc", label: "timestamp_asc"
    config.add_sort_field "score desc, timestamp desc", label: "relevance"
    config.add_sort_field "title_sorted_ssi asc", label: "title_A-Z"
    config.add_sort_field "title_sorted_ssi desc", label: "title_Z-A"
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
    config.view.maps.placename_field = Solr::SchemaFields.facet('placename_field')
    config.view.maps.geojson_field = Solr::SchemaFields.searchable_symbol('geojson')
    config.view.maps.search_mode = 'coordinates'
    config.view.maps.spatial_query_dist = 0.5
  end

  def self.controller_path
    'my_collections'
  end

  def index
    @response = search_service.search_results.first
    @document_list = @response.documents
    load_assets_for_document_list if params[:mode].presence == 'objects'
    load_collection_titles

    @available_timelines = available_timelines_from_facets
    if params[:view].present? && params[:view].include?('timeline')
      @timeline_data = timeline_data
    end

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
    @response = search_service.fetch(params[:id]).first
    @document = @response.documents.first
    if @document.generic_file?
      @document = nil
      raise DRI::Exceptions::BadRequest, "Invalid object type DRI::GenericFile"
    end

    if @document.collection?
      # published subcollections unless admin or edit permission
      @children = @document.children(limit: 100).select { |child| child.published? || (current_user.is_admin? || can?(:edit, @document)) }
      @file_display_type_count = @document.file_display_type_count
      @config = CollectionConfig.find_by(collection_id: @document.id)
    else
      # assets including preservation only files, ordered by label
      @assets = @document.assets(with_preservation: true, ordered: true)
    end

    @reader_group = find_reader_group(@document)

    if @document.doi
      doi = DataciteDoi.where(object_id: @document.id).current
      @doi = doi.doi if doi.present? && doi.minted?
    end

    # Get any aggregation config
    @aggregation = (Aggregation.find_by(collection_id: @document.id) || Aggregation.new) if @document.collection?
    tpstory = TpStory.where(dri_id: @document.id)
    @tp_ready = tpstory.size > 0 ? true : false
    if @tp_ready 
      tpitems = TpItem.where(story_id: tpstory.first.story_id)
      @tp_fetched = tpitems.size > 0 ? true : false
    end

    @presenter = DRI::ObjectInMyCollectionsPresenter.new(@document, view_context)
    @track_download = false

    supported_licences
    supported_copyrights

    respond_to do |format|
      format.html { @search_context = setup_next_and_previous_documents }
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

    @object = SolrDocument.find(params[:id])
    raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') + " ID: #{params[:id]}" if @object.nil?

    params[:per_page] ||= blacklight_config.default_per_page
    @response, document_list = @object.duplicates(params[:sort])
    @document_list = Kaminari.paginate_array(document_list).page(params[:page]).per(params[:per_page])
  end

  private

    def find_reader_group(document)
      read_groups = document["#{Solr::SchemaFields.searchable_symbol('read_access_group')}"]

      if read_groups.present? && read_groups.include?(document.alternate_id)
        UserGroup::Group.find_by(name: document.alternate_id)
      end
    end

    def search_service
      search_service_class.new(
        config: blacklight_config,
        user_params: search_state.to_h.merge({"q" => params[:q_ws]}),
        current_ability: current_ability
      )
    end
end
