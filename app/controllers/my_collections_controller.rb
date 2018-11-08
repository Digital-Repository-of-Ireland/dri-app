# -*- encoding : utf-8 -*-
class MyCollectionsController < ApplicationController
  # authentication must always happen before including DIR::catalog,
  # otherwise enforce_search_for_show_permissions in catalog will return 401
  # even when the user provides a valid api key
  before_action :authenticate_user_from_token!
  include DRI::Catalog
  before_action :authenticate_user!

  # This applies appropriate access controls to all solr queries
  MyCollectionsController.solr_search_params_logic += [:add_workspace_access_controls_to_solr_params]
  # This filters out objects that you want to exclude from search results, like FileAssets
  MyCollectionsController.search_params_logic += [:subject_place_filter, :exclude_unwanted_models, :configure_timeline]

  configure_blacklight do |config|
    config.show.route = { controller: 'my_collections' }
    config.per_page = [9, 18, 36]
    config.default_per_page = 9

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
    config.add_facet_field solr_name('person', :facetable), limit: 20
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
    # use this instead if you don't want to query facets marked :show=>false
    # config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


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

    # config.add_search_field('author') do |field|
    #  field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
    #  field.solr_local_parameters = {
    #    :qf => '$author_qf',
    #    :pf => '$author_pf'
    #  }
    # end

    config.add_search_field('person') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'person'}
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

  def exclude_unwanted_models(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "-#{ActiveFedora.index_field_mapper.solr_name('has_model', :stored_searchable, type: :symbol)}:\"DRI::GenericFile\""
    if user_parameters[:mode] == 'collections'
      solr_parameters[:fq] << "+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true"

      # if show subcollections is false we only want root collections
      # i.e., those without any ancestor ids
      unless user_parameters[:show_subs] == 'true'
        solr_parameters[:fq] << "-#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"
      end
    else
      solr_parameters[:fq] << "+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:false"
      solr_parameters[:fq] << "+#{ActiveFedora.index_field_mapper.solr_name('root_collection_id', :facetable, type: :string)}:\"#{user_parameters[:collection]}\"" if user_parameters[:collection].present?
    end
  end

  def self.controller_path
    'my_collections'
  end

  def index
    params[:q] = params.delete(:q_ws)
    (@response, @document_list) = search_results(params, search_params_logic)

    if params[:view].present? && params[:view].include?('timeline')
      tl_field = params[:tl_field].presence || 'sdate'
      timeline = Timeline.new(view_context)
      @timeline_data = timeline.data(@document_list, tl_field)
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
        formatter = DRI::Formatters::Json.new(@document, options)
        render json: formatter.format(func: :as_json)
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

  def duplicates
    enforce_permissions!('manage_collection', params[:id])

    result = ActiveFedora::SolrService.query("id:#{params[:id]}")
    raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') + " ID: #{params[:id]}" if result.blank?

    @object = SolrDocument.new(result.first)

    params[:per_page] ||= blacklight_config.default_per_page
    @response, document_list = @object.duplicates
    @document_list = Kaminari.paginate_array(document_list).page(params[:page]).per(params[:per_page])
  end

  private

    def find_reader_group(document)
      readgroups = document["#{ActiveFedora.index_field_mapper.solr_name('read_access_group', :stored_searchable, type: :symbol)}"]

      if readgroups.present? && readgroups.include?(document.id)
        UserGroup::Group.find_by(name: document.id)
      end
    end
end
