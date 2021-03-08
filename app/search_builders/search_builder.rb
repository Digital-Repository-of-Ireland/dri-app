# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightMaps::MapsSearchBuilderBehavior
  include Blacklight::AccessControls::Enforcement

  self.default_processor_chain += [
    :subject_place_filter,
    :exclude_unwanted_models,
    :order_subcollections,
    :configure_timeline
  ]

  MAX_TIMELINE_ENTRIES = 50

  EXCLUDE_GENERIC_FILES = "-#{::Solr::SchemaFields.searchable_symbol('has_model')}:\"DRI::GenericFile\"".freeze
  INCLUDE_COLLECTIONS = "+is_collection_ssi:true".freeze
  EXCLUDE_COLLECTIONS = "+is_collection_ssi:false".freeze
  EXCLUDE_SUB_COLLECTIONS = "-ancestor_id_ssim:[* TO *]".freeze
  PUBLISHED_ONLY = "+status_ssi:published".freeze

  def exclude_unwanted_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << EXCLUDE_GENERIC_FILES

    if collections_tab_active(blacklight_params)
      collections_only_filters(solr_parameters, blacklight_params)
    else
      objects_only_filters(solr_parameters, blacklight_params)
    end
  end

  def collections_tab_active(user_parameters)
    user_parameters[:mode] == 'collections'
  end

  def subcollections_tab_active(user_parameters)
    user_parameters[:show_subs] == 'true'
  end

  def collections_only_filters(solr_parameters, user_parameters)
    solr_parameters[:fq] << INCLUDE_COLLECTIONS

    # if show subcollections is false we only want root collections
    # i.e., those without any ancestor ids
    if !subcollections_tab_active(user_parameters)
      solr_parameters[:fq] << EXCLUDE_SUB_COLLECTIONS
    end
  end

  def objects_only_filters(solr_parameters, user_parameters)
    solr_parameters[:fq] << EXCLUDE_COLLECTIONS
    if user_parameters[:collection].present?
      solr_parameters[:fq] << "+root_collection_id_ssi:\"#{user_parameters[:collection]}\""
    end
  end

  def order_subcollections(solr_parameters)
    return unless subcollections_tab_active(blacklight_params) && blacklight_params.dig(:f, :root_collection_id_sim).present?
    solr_parameters[:sort] = 'system_create_dtsi asc' unless blacklight_params.key?(:sort)
  end

  # If querying geographical_coverage, then query the Solr geospatial field
  #
  def subject_place_filter(solr_parameters)
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

  def configure_timeline(solr_parameters)
    if blacklight_params[:view] == 'timeline'
      tl_field = blacklight_params[:tl_field].presence || 'sdate'
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
      solr_parameters[:start] = if blacklight_params[:tl_page].present? && blacklight_params[:tl_page].to_i > 1
                                  MAX_TIMELINE_ENTRIES * (blacklight_params[:tl_page].to_i - 1)
                                else
                                  0
                                end
    else
      blacklight_params.delete(:tl_page)
      blacklight_params.delete(:tl_field)
    end
  end
end
