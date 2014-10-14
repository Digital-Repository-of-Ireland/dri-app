# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'institute_helpers'

# Blacklight catalog controller
#
class CatalogController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  # Extend Blacklight::Catalog with Hydra behaviors (primarily editing).
  include UserGroup::SolrAccessControls
  #This method shows the DO if the metadata is open
  #Rather than before where the user had to have read permissions on the object all the time
  def enforce_search_for_show_permissions
    enforce_permissions!("show_digital_object",params[:id])
  end
  # These before_filters apply the hydra access controls
  before_filter :enforce_search_for_show_permissions, :only=>:show
  # This applies appropriate access controls to all solr queries
  CatalogController.solr_search_params_logic += [:add_access_controls_to_solr_params]
  # This filters out objects that you want to exclude from search results, like FileAssets
  CatalogController.solr_search_params_logic += [:exclude_unwanted_models]
  #CatalogController.solr_search_params_logic += [:exclude_unwanted_models, :exclude_collection_models]

  def rows_per_page
    result = 15

    if (params.include?(:per_page))
      rows_per_page = params[:per_page].to_i

      if (rows_per_page < 1) || (rows_per_page > 100)
        rows_per_page = 9
      end
    end
  end

  configure_blacklight do |config|

    config.default_solr_params = {
      :defType => "edismax",
      :qt => 'search',
      :rows => 9
    }

    # solr field configuration for search results/index views
    config.index.title_field = solr_name('title', :stored_searchable, type: :string)
    config.index.record_tsim_type = solr_name('has_model', :stored_searchable, type: :symbol)

    # solr field configuration for document/show views
    config.show.title_field = solr_name('title', :stored_searchable, type: :string)
    config.show.display_type_field = solr_name('file_type', :stored_searchable, type: :string)

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

    #config.add_facet_field solr_name('status', :facetable), :label => 'Record Status'
    #config.add_facet_field "private_metadata_isi", :label => 'Metadata Search Access', :helper_method => :label_permission
    #config.add_facet_field "master_file_isi", :label => 'Master File Access',  :helper_method => :label_permission
    #}
    config.add_facet_field solr_name('subject', :facetable), :limit => 20
    #config.add_facet_field solr_name('subject_gle', :facetable), :label => 'Subjects (in Irish)'
    #config.add_facet_field solr_name('subject_eng', :facetable), :label => 'Subjects (in English)'
    config.add_facet_field solr_name('geographical_coverage', :facetable), :helper_method => :parse_location, :limit => 20
    #config.add_facet_field solr_name('geographical_coverage_gle', :facetable), :label => 'Subject (Place) (in Irish)', :limit => 20
    #config.add_facet_field solr_name('geographical_coverage_eng', :facetable), :label => 'Subject (Place) (in English)', :limit => 20
    config.add_facet_field solr_name('temporal_coverage', :facetable), :helper_method => :parse_era, :limit => 20
    #config.add_facet_field solr_name('temporal_coverage_gle', :facetable), :label => 'Subject (Era) (in Irish)', :limit => 20
    #config.add_facet_field solr_name('temporal_coverage_eng', :facetable), :label => 'Subject (Era) (in English)', :limit => 20
    #config.add_facet_field solr_name('name_coverage', :facetable), :label => 'Subject (Name)', :limit => 20
    #config.add_facet_field solr_name('creator', :facetable), :label => 'creators', :show => false
    #config.add_facet_field solr_name('contributor', :facetable), :label => 'contributors', :show => false
    config.add_facet_field solr_name('person', :facetable), :limit => 20
    config.add_facet_field solr_name('language', :facetable), :helper_method => :label_language, :limit => true
    #config.add_facet_field solr_name('creation_date', :dateable), :label => 'Creation Date', :date => true
    #config.add_facet_field solr_name('published_date', :dateable), :label => 'Published/Broadcast Date', :date => true
    #config.add_facet_field solr_name('width', :facetable, type: :integer), :label => 'Image Width'
    #config.add_facet_field solr_name('height', :facetable, type: :integer), :label => 'Image Height'
    #config.add_facet_field solr_name('area', :facetable, type: :integer), :label => 'Image Size'

    # duration is measured in milliseconds
    #config.add_facet_field solr_name('duration_total', :stored_sortable, type: :integer), :label => 'Total Duration'

    #config.add_facet_field solr_name('channels', :facetable, type: :integer), :label => 'Audio Channels'
    #config.add_facet_field solr_name('sample_rate', :facetable, type: :integer), :label => 'Sample Rate'
    #config.add_facet_field solr_name('bit_depth', :facetable, type: :integer), :label => 'Bit Depth'
    #config.add_facet_field solr_name('file_count', :stored_sortable, type: :integer), :label => 'Number of Files'
    #config.add_facet_field solr_name('file_size_total', :stored_sortable, type: :integer), :label => 'Total File Size'
    #config.add_facet_field solr_name('mime_type', :facetable), :label => 'MIME Type'
    #config.add_facet_field solr_name('file_format', :facetable), :label => 'File Format'
    config.add_facet_field solr_name('file_type_display', :facetable)
    #config.add_facet_field solr_name('object_type', :facetable), :label => 'Type (from Metadata)'
    #config.add_facet_field solr_name('depositor', :facetable), :label => 'Depositor'
    config.add_facet_field solr_name('institute', :facetable)
    config.add_facet_field solr_name('root_collection_id', :facetable), :helper_method => :collection_title

    config.add_facet_field solr_name('is_collection', :facetable), :label => 'is_collection', :helper_method => :is_collection, :show => false

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name('title', :stored_searchable, type: :string), :label => 'title'
    config.add_index_field solr_name('subject', :stored_searchable, type: :string), :label => 'subjects'
    config.add_index_field solr_name('creator', :stored_searchable, type: :string), :label => 'creators'
    config.add_index_field solr_name('format', :stored_searchable), :label => 'Format:'
    config.add_index_field solr_name('file_type_display', :stored_searchable, type: :string), :label => 'Mediatype'
    config.add_index_field solr_name('language', :stored_searchable, type: :string), :label => 'language', :helper_method => :label_language
    config.add_index_field solr_name('published', :stored_searchable, type: :string), :label => 'Published:'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field solr_name('title', :stored_searchable, type: :string), :label => 'title'
    config.add_show_field solr_name('subtitle', :stored_searchable, type: :string), :label => 'subtitle:'
    config.add_show_field solr_name('description', :stored_searchable, type: :string), :label => 'description'
    config.add_show_field solr_name('scope_content', :stored_searchable, type: :string), :label => 'scope_content'
   config.add_show_field solr_name('scopecontent', :stored_searchable, type: :string), :label => 'scope_content'
    config.add_show_field solr_name('abstract', :stored_searchable, type: :string), :label => 'abstract'
    config.add_show_field solr_name('creator', :stored_searchable, type: :string), :label => 'creators'
    DRI::Vocabulary::marcRelators.each do |role|
      config.add_show_field solr_name('role_'+role, :stored_searchable, type: :string), :label => 'role_'+role
    end
    config.add_show_field solr_name('bioghist', :stored_searchable, type: :string), :label => 'bioghist'
    config.add_show_field solr_name('contributor', :stored_searchable, type: :string), :label => 'contributors'
    config.add_show_field solr_name('creation_date', :stored_searchable), :label => 'creation_date', :date => true
    config.add_show_field solr_name('published_date', :stored_searchable), :label => 'published_date', :date => true
    config.add_show_field solr_name('subject', :stored_searchable, type: :string), :label => 'subjects'
    config.add_show_field solr_name('geographical_coverage', :stored_searchable, type: :string), :label => 'geographical_coverage'
    config.add_show_field solr_name('temporal_coverage', :stored_searchable, type: :string), :label => 'temporal_coverage'
    config.add_show_field solr_name('name_coverage', :stored_searchable, type: :string), :label => 'name_coverage'
    config.add_show_field solr_name('format', :stored_searchable), :label => 'Format:'
    config.add_show_field solr_name('physdesc', :stored_searchable), :label => 'physdesc'
    #config.add_show_field solr_name('object_type', :stored_searchable, type: :string), :label => 'format'
    config.add_show_field solr_name('type', :stored_searchable, type: :string), :label => 'type'
    config.add_show_field solr_name('language', :stored_searchable, type: :string), :label => 'language', :helper_method => :label_language
    config.add_show_field solr_name('source', :stored_searchable, type: :string), :label => 'sources'
    config.add_show_field solr_name('rights', :stored_searchable, type: :string), :label => 'rights'
    config.add_show_field solr_name('properties_status', :stored_searchable, type: :string), :label => 'status'

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

    config.add_search_field 'all_fields', :label => 'All Fields'


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
        :qf => '$title_qf',
        :pf => '$title_pf'
      }
    end

    #config.add_search_field('author') do |field|
    #  field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
    #  field.solr_local_parameters = {
    #    :qf => '$author_qf',
    #    :pf => '$author_pf'
    #  }
    #end

    config.add_search_field('person') do |field|
        field.solr_parameters = { :'spellcheck.dictionary' => 'person'}
        field.solr_local_parameters = {
          :qf => '$person_qf',
          :pf => '$person_pf',
       }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = {
        :qf => '$subject_qf',
        :pf => '$subject_pf'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'system_create_dtsi desc', :label => 'newest'
    # The year created sort throws an error as the date type is not enforced and so a string can be passed in - it is commented out for this reason.
    # config.add_sort_field 'creation_date_dtsim, title_sorted_ssi asc', :label => 'year created'

    # We son't use the author_tesi field in DRI so disabling this sort - Damien
    #config.add_sort_field 'author_tesi asc, title_sorted_ssi asc', :label => 'author'

    config.add_sort_field 'score desc, system_create_dtsi desc, title_sorted_ssi asc', :label => 'relevance'
    config.add_sort_field 'title_sorted_ssi asc, system_create_dtsi desc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  def exclude_unwanted_models(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "+#{Solrizer.solr_name('has_model', :stored_searchable, type: :symbol)}:\"info:fedora/afmodel:Batch\""
    if user_parameters[:mode].eql?('collections')
      solr_parameters[:fq] << "+#{Solrizer.solr_name('is_collection', :facetable, type: :string)}:true"
      solr_parameters[:fq] << "-#{Solrizer.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"
    else
      solr_parameters[:fq] << "+#{Solrizer.solr_name('is_collection', :facetable, type: :string)}:false"
      solr_parameters[:fq] << "+#{Solrizer.solr_name('root_collection_id', :facetable, type: :string)}:\"#{user_parameters[:collection]}\"" if user_parameters[:collection].present?
    end
  end

end
