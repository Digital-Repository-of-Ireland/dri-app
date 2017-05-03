# -*- encoding : utf-8 -*-
require 'iso8601'
require 'iso-639'

# Blacklight catalog controller
#
class CatalogController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  # Extend Blacklight::Catalog with Hydra behaviors (primarily editing).
  include Hydra::AccessControlsEnforcement

  include DRI::Readable

  # This method shows the DO if the metadata is open
  # ather than before where the user had to have read permissions on the object all the time
  def enforce_search_for_show_permissions
    enforce_permissions!("show_digital_object", params[:id])
  end
  # These before_filters apply the hydra access controls
  before_action :enforce_search_for_show_permissions, only: :show

  # Workaround to user_parameters not being persisted in search_params_filter
  #before_action :modify_user_parameters, only: :index

  # This applies appropriate access controls to all solr queries
  CatalogController.search_params_logic += [:add_access_controls_to_solr_params]
  # This filters out objects that you want to exclude from search results, like FileAssets
  CatalogController.search_params_logic += [:subject_place_filter, :exclude_unwanted_models, :configure_timeline]

  MAX_TIMELINE_ENTRIES = 50

  configure_blacklight do |config|
    config.per_page = [9, 18, 36]
    config.default_per_page = 9
    config.metadata_lang = ['all', 'gle', 'enl']
    config.default_metadata_lang = 'all'

    config.default_solr_params = {
      defType: 'edismax',
      qt: 'search',
      rows: 9
    }
    config.show.partials << :show_maplet

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
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #config.add_facet_field "sdateRange", label: 'Subject (Temporal)', date: true #partial: 'custom_date_range'

    config.add_facet_field 'cdate_year_iim', label: 'Creation Date', limit: 20
    config.add_facet_field 'pdate_year_iim', label: 'Published Date', limit: 20
    config.add_facet_field solr_name('subject', :facetable), limit: 20
    config.add_facet_field solr_name('temporal_coverage', :facetable), helper_method: :parse_era, limit: 20, show: true
    config.add_facet_field solr_name('geographical_coverage', :facetable), helper_method: :parse_location, limit: 20
    config.add_facet_field solr_name('placename_field', :facetable), label: 'Placename', show: false
    config.add_facet_field solr_name('geojson', :symbol), limit: -2, label: 'Coordinates', show: false
    config.add_facet_field solr_name('person', :facetable), limit: 20
    config.add_facet_field solr_name('language', :facetable), helper_method: :label_language, limit: true
    config.add_facet_field solr_name('file_type_display', :facetable)
    config.add_facet_field solr_name('institute', :facetable), limit: 10
    config.add_facet_field solr_name('root_collection_id', :facetable), helper_method: :collection_title, limit: 10

    # Added to test sub-collection belonging objects filter in object results view
    config.add_facet_field solr_name('ancestor_id', :facetable), label: 'ancestor_id', helper_method: :collection_title, show: false
    config.add_facet_field solr_name('is_collection', :facetable), label: 'is_collection', helper_method: :is_collection, show: false

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # Solr fields to be displayed in the index (search results) view
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
    config.add_show_field solr_name('description_eng', :stored_searchable, type: :string), label: 'description_eng', helper_method: :render_description
    config.add_show_field solr_name('description_gle', :stored_searchable, type: :string), label: 'description_gle', helper_method: :render_description
    config.add_show_field solr_name('creator', :stored_searchable, type: :string), label: 'creators'
    DRI::Vocabulary.marc_relators.each do |role|
      config.add_show_field solr_name('role_' + role, :stored_searchable, type: :string), label: 'role_' + role
    end
    config.add_show_field solr_name('contributor', :stored_searchable, type: :string), label: 'contributors'
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

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field 'all_fields', label: 'All Fields'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = {
        qf: '$title_qf',
        pf: '$title_pf'
      }
    end

    config.add_search_field('person') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'person' }
      field.solr_local_parameters = {
        qf: '$person_qf',
        pf: '$person_pf'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = {
        qf: '$subject_qf',
        pf: '$subject_pf'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'system_create_dtsi desc', label: 'newest'
    # The year created sort throws an error as the date type is not enforced and so a string can be passed in
    # - it is commented out for this reason.
    # config.add_sort_field 'creation_date_dtsim, title_sorted_ssi asc', label: 'year created'

    # We son't use the author_tesi field in DRI so disabling this sort - Damien
    # config.add_sort_field 'author_tesi asc, title_sorted_ssi asc', label: 'author'

    config.add_sort_field 'score desc, system_create_dtsi desc, title_sorted_ssi asc', label: 'relevance'
    config.add_sort_field 'title_sorted_ssi asc, system_create_dtsi desc', label: 'title'
    config.add_sort_field 'id_asset_ssi asc, system_create_dtsi desc', label: 'order/sequence'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    config.view.maps.coordinates_field = 'geospatial'
    config.view.maps.placename_property = 'placename'
    config.view.maps.tileurl = 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
    config.view.maps.mapattribution = 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>'
    config.view.maps.maxzoom = 18
    config.view.maps.show_initial_zoom = 5
    config.view.maps.facet_mode = 'geojson'
    config.view.maps.placename_field = ActiveFedora.index_field_mapper.solr_name('placename_field', :facetable, type: :string)
    config.view.maps.geojson_field = ActiveFedora.index_field_mapper.solr_name('geojson', :stored_searchable, type: :symbol)
    config.view.maps.search_mode = 'placename'
  end

  # OVER-RIDDEN from BL
  # Get Timeline data if view is Timeline
  def index
    (@response, @document_list) = search_results(params, search_params_logic)

    if params[:view].present? && params[:view].include?('timeline')
      tl_field = params[:tl_field].presence || 'sdate'
      timeline = Timeline.new(view_context)
      @timeline_data = timeline.data(@document_list, tl_field)
    end

    respond_to do |format|
      format.html { store_preferred_view }
      format.rss  { render layout: false }
      format.atom { render layout: false }
      format.json do
        render json: render_search_results_as_json
      end

      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  # get a single document from the index
  # to add responses for formats other than html or json see _Blacklight::Document::Export_
  def show
    @response, @document = fetch params[:id]

    available_institutes
    files_and_surrogates
    supported_licences

    @reader_group = governing_reader_group(@document.collection_id) unless @document.collection?

    respond_to do |format|
      format.html { setup_next_and_previous_documents }
      format.json do
        options = {}
        options[:with_assets] = true if can?(:read, @document)
        formatter = DRI::Formatters::Json.new(@document, options)
        render json: formatter.format
      end
      format.ttl do
        options = {}
        options[:with_assets] = true if can?(:read, @document)
        formatter = DRI::Formatters::Rdf.new(@document, options)
        render text: formatter.format({format: :ttl})
      end
      format.rdf do
        options = {}
        options[:with_assets] = true if can?(:read, @document)
        formatter = DRI::Formatters::Rdf.new(@document, options)
        render text: formatter.format({format: :xml})
      end
      format.js { render layout: false }

      additional_export_formats(@document, format)
    end
  end

  # Excludes objects from the collections view or collections from the objects view
  def exclude_unwanted_models(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "-#{ActiveFedora.index_field_mapper.solr_name('has_model', :stored_searchable, type: :symbol)}:\"DRI::GenericFile\""
    if user_parameters[:mode] == 'collections'
      solr_parameters[:fq] << "+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true"
      unless user_parameters[:show_subs] == 'true'
        solr_parameters[:fq] << "-#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"
      end
    else
      solr_parameters[:fq] << "+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:false"
      if user_parameters[:collection].present?
        solr_parameters[:fq] << "+#{ActiveFedora.index_field_mapper.solr_name('root_collection_id', :facetable, type: :string)}:\"#{user_parameters[:collection]}\""
      end
    end
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
      else
        solr_parameters[:fq] << "+sdateRange:*"
        solr_parameters[:fq] << "+sdate_range_start_isi:[* TO *]"
        solr_parameters[:sort] = "sdate_range_start_isi asc"
      end

      solr_parameters[:rows] = MAX_TIMELINE_ENTRIES

      if params[:tl_page].present? && params[:tl_page].to_i > 1
        solr_parameters[:start] = MAX_TIMELINE_ENTRIES * (params[:tl_page].to_i - 1)
      else
        solr_parameters[:start] = 0
      end
    else
      params.delete(:tl_page)
      params.delete(:tl_field)
    end  
  end

  # method to find the Institutes associated with and available to add to or remove from the current collection (document)
  def available_institutes
    # the full list of Institutes
    @institutes = Institute.all
    # the Institutes currently associated with this collection if any
    @collection_institutes = @document.institutes
    # the Depositing Institute if any
    @depositing_institute = @document.depositing_institute

    @depositors = Institute.where(depositing: true).map { |item| item['name'] }

    institutes_array = []
    collection_institutes_array = []
    depositing_institute_array = []

    depositing_institute_array.push(@depositing_institute.name) unless @depositing_institute.blank?
    @institutes.each { |inst| institutes_array.push(inst.name) }

    @collection_institutes.each { |inst| collection_institutes_array.push(inst.name) } unless @collection_institutes.empty?

    # exclude the associated and depositing Institutes from the list of Institutes available
    @available_institutes = institutes_array - collection_institutes_array - depositing_institute_array
    # exclude the depositing Institute from the list of Institutes which can be removed
    @removal_institutes = collection_institutes_array - depositing_institute_array
  end

  def files_and_surrogates
    # get assets including preservation
    @files = @document.assets(true)
    @files.sort_by! { |f| f[ActiveFedora.index_field_mapper.solr_name('label')] }

    @displayfiles = []
    @surrogates = {}
    @status = {}

    @files.each do |file|
      @displayfiles << file unless file.preservation_only?

      # get the surrogates for this file if they exist
      surrogates = @document.surrogates(file.id)
      if surrogates
        file_list = {}
        surrogates.each do |key, _path|
          file_list[key] = url_for(object_file_url(
                                     object_id: @document.id, id: file.id, surrogate: key
                                  ))
        end

        @surrogates[file.id] = file_list unless file_list.empty?
      end

      file_status(file.id) if @surrogates[file.id].blank?
    end

    ''
  end

  def file_status(file_id)
    ingest_status = IngestStatus.where(asset_id: file_id)
    if ingest_status.present?
      status = ingest_status.first
      @status[file_id] = { status: status.status }
    end
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
