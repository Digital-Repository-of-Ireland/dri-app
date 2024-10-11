# -*- encoding : utf-8 -*-
class CatalogController < ApplicationController
  include DRI::Catalog
  include BlacklightAdvancedSearch::Controller
  self.search_service_class = ::SearchService

  configure_blacklight do |config|

    config.advanced_search = {
      # https://github.com/projectblacklight/blacklight_advanced_search/tree/74d5be9756f2157204d486d37c766162d59bb400/lib/parsing_nesting#why-not-use-e-dismax
      # support wildcards in advanced search
      query_parser: 'edismax',
      url_key: 'advanced',
      form_solr_parameters: {}
    }
    #config.document_unique_id_param = 'alternate_id'
    config.search_builder_class = ::CatalogSearchBuilder

    config.show.route = { controller: 'catalog' }
    config.per_page = [12, 24, 36, 48]
    config.default_per_page = 12
    config.metadata_lang = ['all', 'gle', 'enl']
    config.default_metadata_lang = 'all'

    config.default_solr_params = {
      defType: 'edismax',
      qt: 'search',
      rows: 9
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'title_tesim'
    config.index.record_tsim_type = 'has_model_ssim'

    # solr field configuration for document/show views
    config.show.title_field = 'title_tesim'
    config.show.display_type_field = 'file_type_tesim'

    config.show.document_actions.delete(:email)
    config.show.document_actions.delete(:sms)
    config.show.document_actions.delete(:citation)
    config.add_show_tools_partial(:bookmark, partial: 'catalog/bookmark_control')

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field 'cdate_year_iim', label: 'Creation Date', limit: 20
    config.add_facet_field 'pdate_year_iim', label: 'Published Date', limit: 20

    config.add_facet_field 'cdate_range_start_isi', show: false
    config.add_facet_field 'sdate_range_start_isi', show: false
    config.add_facet_field 'pdate_range_start_isi', show: false
    config.add_facet_field 'date_range_start_isi', show: false

    config.add_facet_field 'licence_sim', label: 'Licence', limit: 20
    config.add_facet_field 'copyright_sim', label: 'Copyright', limit: 20
    config.add_facet_field 'subject_sim', limit: 20
    config.add_facet_field 'temporal_coverage_sim', helper_method: :parse_era, limit: 20, show: true
    config.add_facet_field 'geographical_coverage_sim', helper_method: :parse_location, show: false
    config.add_facet_field 'placename_field_sim', show: true, limit: 20
    config.add_facet_field 'creator_sim', label: 'creators', show: false
    config.add_facet_field 'contributor_sim', label: 'contributors', show: false
    config.add_facet_field 'person_sim', limit: 20, helper_method: :parse_orcid
    config.add_facet_field 'language_sim', helper_method: :label_language, limit: true
    config.add_facet_field 'file_type_display_sim'
    config.add_facet_field 'institute_sim', limit: 10
    config.add_facet_field 'root_collection_id_ssi', helper_method: :collection_title, limit: 10
    config.add_facet_field 'visibility_ssi'

    # Added to test sub-collection belonging objects filter in object results view
    config.add_facet_field 'ancestor_id_ssim', label: 'ancestor_id', helper_method: :collection_title, show: false
    config.add_facet_field 'is_collection_ssi', label: 'is_collection', helper_method: :is_collection, show: false
    
    config.add_facet_fields_to_solr_request!

    # Solr fields to be displayed in the index (search results) view
    # The ordering of the field names is the order of the display
    config.add_index_field 'title_tesim', label: 'title'
    config.add_index_field 'subject_tesim', label: 'subjects'
    config.add_index_field 'creator_tesim', label: 'creators'
    config.add_index_field 'format_tesim', label: 'format'
    config.add_index_field 'file_type_display_tesim', label: 'Mediatype'
    config.add_index_field 'language_tesim', label: 'language', helper_method: :label_language
    config.add_index_field 'published_tesim', label: 'Published:'

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
    config.add_show_field Solrizer.solr_name('publisher', :stored_searchable), label: 'publishers'
    config.add_show_field Solrizer.solr_name('creation_date', :stored_searchable), label: 'creation_date', date: true, helper_method: :parse_era
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

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

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

    # "sort results by" options
    config.add_sort_field "published_at_dttsi desc", label: "newest"
    config.add_sort_field "title_sorted_ssi asc", label: "title_A-Z"
    config.add_sort_field "title_sorted_ssi desc", label: "title_Z-A"
    config.add_sort_field "id_asset_ssi asc, system_create_dtsi desc", label: "order/sequence"
    config.add_sort_field "score desc, title_sorted_ssi asc", label: "relevance"

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
    config.view.maps.placename_field = ::Solr::SchemaFields.facet('placename_field')
    config.view.maps.geojson_field = ::Solr::SchemaFields.searchable_symbol('geojson')
    config.view.maps.search_mode = 'coordinates'
    config.view.maps.spatial_query_dist = 0.5

    config.oai = {
      provider: {
        repository_name: 'Digital Repository of Ireland',
        repository_url: 'https://repository.dri.ie/oai',
        record_prefix: 'oai:dri',
        admin_email: 'tech@dri.ie',
      },
      document: {
        limit: 100,            # number of records returned with each request, default: 15
        set_model: DRI::OaiProvider::AncestorSet,
        set_fields: [        # ability to define ListSets, optional, default: nil
          { label: 'collection', solr_field: 'ancestor_id_ssim' }
        ]
      }
    }
  end

  # OVER-RIDDEN from BL
  def index
    params.delete(:q_ws)

    # geojson facet is slow to load
    if params[:view].presence == 'maps'
      blacklight_config.add_facet_field 'geojson_ssim', limit: -2, label: 'Coordinates', show: false
    end

    @response = search_service.search_results.first
    @document_list = @response.documents
    load_assets_for_document_list if params[:mode].presence == 'objects'
    @collection_titles = Rails.cache.fetch('root_collection_titles', expires_in: 12.hours) {
      load_collection_titles
    }
    
    # Get Timeline data if view is Timeline
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

    show_organisations

    if @document.collection?
      @children = @document.children(limit: 100).select { |child| child.published? }
      @file_display_type_count = @document.file_display_type_count(published_only: true)
      @config = CollectionConfig.find_by(collection_id: @document.id)
    else
      # assets ordered by label, excludes preservation only files
      @assets = @document.assets(ordered: true)
    end

    @presenter = DRI::ObjectInCatalogPresenter.new(@document, view_context)
    @reader_group = governing_reader_group(@document.collection_id) unless @document.collection?

    if @document.doi
      doi = DataciteDoi.where(object_id: @document.id).current
      @doi = doi.doi if doi.present? && doi.minted?
    end

    if @document.published?
      dimensions = { collection: @document.root_collection_id, object: @document.id }
      dimensions[:organisation] = @document.depositing_institute.name if @document.depositing_institute.present?
      @dimensions = dimensions
      @track_download = true
    end

    respond_to do |format|
      format.html { @search_context = setup_next_and_previous_documents }
      format.json do
        options = {}
        options[:with_assets] = true if can?(:read, @document)
        options[:with_metadata] = true
        formatter = DRI::Formatters::Json.new(self, @document, options)
        render json: formatter.format(func: :as_json)
      end
      format.ttl do
        options = {}
        options[:with_assets] = true if can?(:read, @document)
        options[:with_metadata] = true
        formatter = DRI::Formatters::Rdf.new(self, @document, options)
        render plain: formatter.format({format: :ttl})
      end
      format.rdf do
        options = {}
        options[:with_assets] = true if can?(:read, @document)
        options[:with_metadata] = true
        formatter = DRI::Formatters::Rdf.new(self, @document, options)
        render plain: formatter.format({format: :xml})
      end
      format.js { render layout: false }

      additional_export_formats(@document, format)
    end
  end

  private

  def search_service
    search_service_class.new(
      config: blacklight_config,
      user_params: search_state.to_h,
      current_ability: current_ability
    )
  end
end
