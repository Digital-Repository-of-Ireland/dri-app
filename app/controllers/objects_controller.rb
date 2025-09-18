# frozen_string_literal: true
# Controller for Digital Objects
#
require 'solr/query'

class ObjectsController < BaseObjectsController
  include Blacklight::AccessControls::Catalog
  include DRI::Duplicable
  include Preservation::PreservationHelpers

  before_action :authenticate_user_from_token!, except: [:show, :citation]
  before_action :authenticate_user!, except: [:show, :citation]
  before_action :read_only, except: [:show, :citation, :retrieve]
  before_action ->(id = params[:id]) { locked(id) }, except: [:show, :citation, :new, :create, :retrieve]

  module PrimaryTypes
    TYPES = %w[text image movingImage interactiveResource 3D sound software dataset].freeze
  end

  # Displays the New Object form
  #
  def new
    @collection = params[:collection]
    locked(@collection)
    return if performed?

    @object = DRI::DigitalObject.with_standard :qdc
    @object.creator = ['']

    @object.type = ['Collection'] if params[:is_sub_collection].present? && params[:is_sub_collection] == 'true'

    supported_licences
    supported_copyrights
  end

  # Edits an existing model.
  #
  def edit
    enforce_permissions!('edit', params[:id])

    supported_licences
    supported_copyrights

    @object = retrieve_object!(params[:id])
    @object.creator = [''] unless @object.creator[0]
    @standard = metadata_standard

    # sets the primary type as the first in the array if found elsewhere
    reorder_types

    # used for crumbtrail
    @document = SolrDocument.new(@object.to_solr)

    flash[:alert] = t('dri.flash.alert.doi_published_warning').to_s.html_safe if @document.published? && @document.doi.present?

    respond_to do |format|
      format.html
      format.json { render json: @object }
    end
  end

  def show
    enforce_permissions!('show_digital_object', params[:id])
    @object = retrieve_object!(params[:id])

    respond_to do |format|
      format.html { redirect_to(catalog_url(@object.alternate_id)) }
      format.endnote { render plain: @object.export_as_endnote, layout: false }
      format.json do
        json = @object.as_json
        solr_doc = SolrDocument.find(@object.alternate_id)

        json['licence'] = DRI::Formatters::Json.licence(solr_doc)
        json['copyright'] = DRI::Formatters::Json.copyright(solr_doc)
        json['doi'] = DRI::Formatters::Json.dois(solr_doc)
        json['related_objects'] = solr_doc.object_relationships_as_json
        render json: json
      end
      format.zip do
        if current_user
          Resque.enqueue(CreateArchiveJob, params[:id], current_user.email)

          flash[:notice] = t('dri.flash.notice.archiving')
        else
          flash[:alert] = t('dri.flash.alert.archiving_login')
        end
        redirect_back(fallback_location: root_path)
      end
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    enforce_permissions!('edit', params[:id])

    supported_licences
    supported_copyrights
    @object = retrieve_object!(params[:id])

    if params[:digital_object][:governing_collection_id].present?
      collection = retrieve_object(params[:digital_object][:governing_collection_id])
      @object.governing_collection = collection
    end

    @object.assign_attributes(update_params)

    respond_to do |format|
      unless @object.valid?
        flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
        format.html { render action: 'edit' }
        return
      end

      @object.increment_version
      checksum_metadata(@object)

      if save_and_index
        post_save do
          mint_or_update_doi(@object, doi) if doi
        end

        flash[:notice] = t('dri.flash.notice.metadata_updated')
        format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
        format.json { render json: @object }
      else
        flash[:alert] = t('dri.flash.error.unable_to_persist')
        format.html { render action: 'edit' }
      end
    end
  end

  def citation
    enforce_permissions!('show_digital_object', params[:id])

    @object = retrieve_object!(params[:id])
    document = SolrDocument.find(@object.alternate_id)
    @depositing_institute = document.depositing_institute&.name

    return if @object.doi.blank?
    doi = DataciteDoi.where(object_id: @object.alternate_id).current
    @doi = doi.doi if doi.present? && doi.minted?
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    downcase_permissions_params

    if params[:governing_collection_id].present?
      @governing_collection = retrieve_object!(params[:governing_collection_id])
    else
      after_create_failure(DRI::Exceptions::BadRequest)
    end

    enforce_permissions!('create_digital_object', @governing_collection)
    locked(@governing_collection.alternate_id)
    return if performed?

    if params[:documentation_for].present?
      create_from_form :documentation
    elsif params[:metadata_file].present?
      create_from_upload
    else
      create_from_form
    end

    @object.governing_collection = @governing_collection
    @object.visibility = if @object.read_groups_string.present?
                           visibility_label(@object.read_groups_string)
                         else
                           cdoc = SolrDocument.find(@governing_collection.alternate_id)
                           cdoc.ancestor_field('visibility_ssi')
                         end

    unless @object.valid?
      flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
      if params[:metadata_file].present?
        after_create_failure(DRI::Exceptions::BadRequest)
      else
        render :new
        return
      end
    end

    checksum_metadata(@object)
    supported_licences
    supported_copyrights
    begin
      if save_and_index
        post_save do
          create_reader_group if @object.collection?
        end

        after_create_success(@object, @warnings)
      else
        after_create_failure(DRI::Exceptions::InternalError) if params[:metadata_file].present?

        flash[:alert] = t('dri.flash.error.unable_to_persist')
        render :new
      end
    rescue DRI::SolrBadRequest => e
      flash[:alert] = t('dri.flash.alert.invalid_object', error: e.details)
      redirect_back(fallback_location: root_path)
      nil
    end
  end

  def destroy
    enforce_permissions!('edit', params[:id])

    @object = retrieve_object(params[:id])

    if @object.nil?
      solr_object = SolrDocument.find(params[:id])
      raise DRI::Exceptions::NotFound, t('dri.views.exceptions.unknown_object') + " ID: #{params[:id]}" unless solr_object
      collection_id = solr_object.collection_id
      SolrDocument.delete(params[:id])
    else
      raise Blacklight::AccessControls::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '') if @object.status == 'published' && !current_user.is_admin?
      
      if @object.status == 'published'
        # Do the preservation actions
        @object.increment_version
        assets = []
        @object.generic_files.map { |gf| assets << "#{gf.alternate_id}_#{gf.label}" }
        
        preservation = Preservation::Preservator.new(@object)
        preservation.update_manifests(
          deleted: {
            'content' => assets,
            'metadata' => ['descMetadata.xml']
          }
        )
        record_version_committer(@object, current_user)
      else
        # clean up MOAB
        preservation = Preservation::Preservator.new(@object)
        preservation.remove_moab_dirs
      end

      collection_id = @object.governing_collection.alternate_id
      @object.destroy
    end

    flash[:notice] = t('dri.flash.notice.object_deleted')

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: collection_id }
    end
  end

  def retrieve
    id = params[:id]
    object = SolrDocument.find(id)

    if object.present?
      if can?(:read, object)
        if File.file?(File.join(Settings.dri.downloads, params[:archive]))
          response.headers['Content-Length'] = File.size?(params[:archive]).to_s
          send_file File.join(Settings.dri.downloads, params[:archive]),
                type: "application/zip",
                stream: true,
                buffer: 4096,
                disposition: "attachment; filename=\"#{id}.zip\";",
                url_based_filename: true

          return
        else
          flash[:error] = t('dri.flash.error.download_no_file')
        end
      else
        flash[:alert] = t('dri.flash.alert.read_permission')
      end
    end

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'index' }
    end
  end

  def status
    enforce_permissions!('edit', params[:id])
    return if request.get?
    @object = retrieve_object!(params[:id])

    raise DRI::Exceptions::BadRequest if @object.collection? || params[:status].blank?

    if @object.status != 'published' || current_user.is_admin?
      @object.status = params[:status]
      @object.published_at = Time.now.utc.iso8601 if @object.published_at.nil? && params[:status] == 'published'
      @object.increment_version
      @object.save

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve

      # if this object is in a sub-collection, we need to set that collection status
      # to reviewed so that a publish job will run on the collection
      set_ancestors_reviewed if params[:status] == 'reviewed'
    end

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.metadata_updated')
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
      format.json do
        response = { id: @object.alternate_id, status: @object.status }
        response[:warning] = @warnings if @warnings
        render json: response, status: :accepted
      end
    end
  end

  def set_licence
    enforce_permissions!('edit', params[:id])

    super
  end

  def set_copyright
    enforce_permissions!('edit', params[:id])

    super
  end

  private

  def after_create_failure(exception)
    respond_to do |format|
      format.html do
        raise exception
      end
      format.json do
        raise exception
      end
    end
  end

  def after_create_success(object, warnings)
    respond_to do |format|
      format.html do
        flash[:notice] = t('dri.flash.notice.digital_object_ingested')
        redirect_to controller: 'my_collections', action: 'show', id: object.alternate_id
      end
      format.json do
        response = { pid: object.alternate_id }
        response[:warning] = warnings if warnings

        render json: response, location: my_collections_url(object.alternate_id), status: :created
      end
    end
  end

  def create_from_upload
    xml_ds = XmlDatastream.new
    xml = xml_ds.load_xml(params[:metadata_file])

    @object = DRI::DigitalObject.with_standard xml_ds.metadata_standard

    @object.depositor = current_user.to_s
    @object.assign_attributes create_params
    @object.update_metadata xml
  end

  # If no standard parameter then default to :qdc
  # allow to create :documentation and :marc objects (improve merging into marc-nccb branch)
  def create_from_form(type = :qdc)
    if type == :documentation
      @object = DRI::Documentation.new
      @documented = retrieve_object(params[:documentation_for])
      @object.documentation_for = @documented if @documented
      @object.read_groups = ["public"]
    else
      @object = DRI::DigitalObject.with_standard(type)
    end

    @object.depositor = current_user.to_s
    @object.assign_attributes create_params
  end

  def create_reader_group
    group = UserGroup::Group.new(
      name: @object.alternate_id,
      description: "Default Reader group for collection #{@object.alternate_id}"
    )
    group.reader_group = true
    group.save
  end

  def downcase_permissions_params
    return if params[:digital_object].blank?

    params[:digital_object][:read_users_string] = params[:digital_object][:read_users_string].to_s.downcase if params[:digital_object][:read_users_string].present?
    params[:digital_object][:edit_users_string] = params[:digital_object][:edit_users_string].to_s.downcase if params[:digital_object][:edit_users_string].present?
  end

  def metadata_standard
    @object.descMetadata.class.to_s.downcase.split('::').last
  end

  def reorder_types
    return if PrimaryTypes::TYPES.include?(@object.type.first)

    primary_type_index, object_type_index = nil
    @object.type.each_with_index do |x, x_index|
      next unless (y_index = PrimaryTypes::TYPES.index { |y| y.downcase == x.downcase.delete(' ') })
      primary_type_index = y_index
      object_type_index = x_index
      break
    end

    return unless primary_type_index && object_type_index
    primary_type = PrimaryTypes::TYPES[primary_type_index]
    object_types = @object.type.to_a
    object_types.delete_at(object_type_index)
    @object.type = [primary_type] + object_types
  end

  def save_and_index
    @object.index_needs_update = false

    DRI::DigitalObject.transaction do
      if doi
        doi_params = update_params.select { |key, _value| doi.metadata_fields.include?(key) }
        doi_params[:resource_type] = doi_params.delete(:type) if doi_params.key?(:type)
        doi.update_metadata(doi_params)
        new_doi_if_required(@object, doi, 'metadata updated')
      end

      begin
        if @object.save && @object.update_index
          true
        else
          raise ActiveRecord::Rollback
          false
        end
      rescue RSolr::Error::Http => e
        raise DRI::SolrBadRequest.new(e.request, e.response) if e.response[:status] == 400
        raise ActiveRecord::Rollback
        false
      end
    end
  end

  def post_save
    warn_if_has_duplicates(@object)
    retrieve_linked_data if AuthoritiesConfig
    record_version_committer(@object, current_user)

    yield

    # Do the preservation actions
    preservation = Preservation::Preservator.new(@object)
    datastreams = ['descMetadata']
    preservation.preserve(datastreams)
  end

  def retrieve_linked_data
    DRI.queue.push(LinkedDataJob.new(@object.alternate_id)) if @object.geographical_coverage.present? || @object.coverage.present?
  rescue Exception => e
    Rails.logger.error "Unable to submit linked data job: #{e.message}"
  end

  def set_ancestors_reviewed
    governing_collection = @object.governing_collection

    while governing_collection.root_collection? == false
      if governing_collection.status == 'draft'
        governing_collection.status = 'reviewed'
        governing_collection.increment_version
        governing_collection.save

        # Do the preservation actions
        preservation = Preservation::Preservator.new(governing_collection)
        preservation.preserve
      end

      governing_collection = governing_collection.governing_collection
    end
  end
end
