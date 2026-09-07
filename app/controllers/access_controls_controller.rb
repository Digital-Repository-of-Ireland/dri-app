class AccessControlsController < ApplicationController
  before_action :read_only, except: :edit
  before_action ->(id = params[:id]) { locked(id) }, except: :edit

  include DRI::Versionable

  def edit
    @object = retrieve_object!(params[:id])
    enforce_manage_or_edit_permissions!

    respond_to do |format|
      format.js
    end
  end

  def update
    @object = retrieve_object!(params[:id])
    enforce_manage_or_edit_permissions!

    normalize_update_params!

    updated = @object.update(update_params) unless @object.collection? && !valid_permissions?

    if updated
      flash[:notice] = t('dri.flash.notice.access_controls_updated')

      record_version_committer(@object, current_user, 'access controls update')

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve

      Resque.enqueue(VisibilityJob, @object.alternate_id)
    else
      flash[:alert] = t('dri.flash.error.access_controls_not_updated')
    end

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
    end
  end

  def show
    enforce_permissions!('manage_collection', params[:id])
    @collection = SolrDocument.find(params[:id])
    @collection_id = @collection.id
    @title = @collection['title_tesim'].first

    collections = [@collection].concat(@collection.descendants)

    respond_to do |format|
      format.html do
        entries = DRI::AccessControls::TreeBuilder.entries_for(collections)
        @access_controls = DRI::AccessControls::TreeBuilder.nest(entries)
      end
      format.csv do
        send_data DRI::AccessControls::CsvExporter.generate(collections),
                  filename: "#{@title.parameterize}-access-controls-#{Date.today}.csv"
      end
    end
  end

  private

    def enforce_manage_or_edit_permissions!
      @object.collection? ? enforce_permissions!('manage_collection', params[:id]) : enforce_permissions!('edit', params[:id])
    end

    def normalize_update_params!
      params[:digital_object][:read_users_string] = params[:digital_object][:read_users_string].to_s.downcase
      params[:digital_object][:edit_users_string] = params[:digital_object][:edit_users_string].to_s.downcase
      if params[:digital_object][:manager_users_string].present?
        params[:digital_object][:manager_users_string] = params[:digital_object][:manager_users_string].to_s.downcase
      end
      params[:digital_object][:object_version] = @object.increment_version
    end

    def update_params
      params.require(:digital_object).permit(
        :read_groups_string,
        :read_users_string,
        :master_file_access,
        :edit_users_string,
        :manager_users_string,
        :object_version,
      )
    end

    # Collections can only have their access controls updated directly
    # when they have no governing collection (i.e. are root-level), or
    # when manager/editor permissions are explicitly being set.
    def valid_permissions?
      !(
        @object.governing_collection_id.blank? &&
        params[:digital_object][:manager_users_string].blank? &&
        params[:digital_object][:edit_users_string].blank?
      )
    end
end