require 'iso8601'
require 'iso-639'

module DRI::Catalog
  extend ActiveSupport::Concern

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Hydra::AccessControlsEnforcement
  include DRI::Readable

  MAX_TIMELINE_ENTRIES = 50

  included do
    # These before_filters apply the hydra access controls
    before_action :enforce_search_for_show_permissions, only: :show
  end

  private

    # This method shows the DO if the metadata is open
    # rather than before where the user had to have read permissions on the object all the time
    def enforce_search_for_show_permissions
      enforce_permissions!("show_digital_object", params[:id])
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

    def relationships
      @relationships = object_relationships
      @external_relationships = external_relationships
    end

    def external_relationships
      Kaminari.paginate_array(@document.external_relationships).page(params[:externs_page]).per(4)
    end

    def object_relationships
      relationships = @document.object_relationships
      filtered_relationships = {}

      relationships.each do |key, array|
        filtered_array = array.select { |item| item[1].published? || ((current_user && current_user.is_admin?) || can?(:edit, item[1])) }
        unless filtered_array.empty?
          filtered_relationships[key] = Kaminari.paginate_array(filtered_array).page(params[key.downcase.gsub(/\s/, '_') << '_page']).per(4)
        end
      end

      filtered_relationships
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
