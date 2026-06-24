# frozen_string_literal: true
# Controller for Digital Objects
require 'solr/query'

class ObjectsController < BaseObjectsController
  include Blacklight::AccessControls::Catalog
  include DRI::Duplicable
  include Preservation::PreservationHelpers

  before_action :authenticate_user_from_token!, except: [:show, :citation]
  before_action :authenticate_user!,            except: [:show, :citation]
  before_action :read_only,                     except: [:show, :citation, :retrieve]
  before_action ->(id = params[:id]) { locked(id) }, except: [:show, :citation, :new, :create, :retrieve]

  module PrimaryTypes
    TYPES = %w[text image movingImage interactiveResource 3D sound software dataset].freeze
  end

  def new
    @collection = params[:collection]
    locked(@collection)
    return if performed?

    @object = DRI::DigitalObject.with_standard(:qdc)
    @object.creator = ['']
    @object.type    = ['Collection'] if sub_collection_param?

    supported_licences
    supported_copyrights
  end

  def edit
    enforce_permissions!('edit', params[:id])
    supported_licences
    supported_copyrights

    @object   = retrieve_object!(params[:id])
    @object.creator = [''] unless @object.creator[0]
    @standard = metadata_standard

    reorder_types

    @document = SolrDocument.new(@object.to_solr)
    flash[:alert] = t('dri.flash.alert.doi_published_warning').to_s.html_safe if doi_published_warning?

    respond_to do |format|
      format.html
      format.json { render json: @object }
    end
  end

  def show
    enforce_permissions!('show_digital_object', params[:id])
    @object = retrieve_object!(params[:id])

    respond_to do |format|
      format.html      { redirect_to(catalog_url(@object.alternate_id)) }
      format.endnote   { render plain: @object.export_as_endnote, layout: false }
      format.json      { render json: build_show_json }
      format.zip       { handle_zip_request }
    end
  end

  def update
    enforce_permissions!('edit', params[:id])
    supported_licences
    supported_copyrights

    @object = retrieve_object!(params[:id])
    assign_governing_collection
    @object.assign_attributes(update_params)

    return render_invalid_object('edit') unless @object.valid?

    @object.increment_version
    checksum_metadata(@object)

    result = ObjectSaveService.new(@object, doi: doi, doi_params: doi_update_params).call

    if result.success?
      doi_sync = result.doi_sync
      ObjectPostSaveService.new(@object).call do
        warn_if_has_duplicates(@object)
        record_version_committer(@object, current_user, 'update')
        doi_sync&.enqueue_job(doi)
      end
      flash[:notice] = t('dri.flash.notice.metadata_updated')
      respond_to do |format|
        format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
        format.json { render json: @object }
      end
    else
      handle_save_failure(result.error, 'edit')
    end
  end

  def citation
    enforce_permissions!('show_digital_object', params[:id])
    @object = retrieve_object!(params[:id])

    @depositing_institute = SolrDocument.find(@object.alternate_id).depositing_institute&.name
    return if @object.doi.blank?

    doi = DataciteDoi.where(object_id: @object.alternate_id).current
    @doi = doi.doi if doi.present? && doi.minted?
  end

  def create
    downcase_permissions_params
    resolve_governing_collection
    return unless governing_collection_present?

    enforce_permissions!('create_digital_object', @governing_collection)
    locked(@governing_collection.alternate_id)
    return if performed?

    build_object_for_create
    assign_object_visibility

    return handle_invalid_object_on_create unless @object.valid?

    checksum_metadata(@object)
    supported_licences
    supported_copyrights
    persist_new_object
  end

  def destroy
    enforce_permissions!('edit', params[:id])
    @object = retrieve_object(params[:id])

    collection_id = if @object.nil?
                      destroy_solr_only_object
                    else
                      destroy_full_object
                    end

    flash[:notice] = t('dri.flash.notice.object_deleted')
    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: collection_id }
    end
  end

  def retrieve
    id     = params[:id]
    object = SolrDocument.find(id)

    if object.present? && can?(:read, object)
      archive = File.join(Settings.dri.downloads, params[:archive])
      if File.file?(archive)
        return send_file archive,
          type:              'application/zip',
          stream:            true,
          buffer:            4096,
          disposition:       "attachment; filename=\"#{id}.zip\";",
          url_based_filename: true
      else
        flash[:error] = t('dri.flash.error.download_no_file')
      end
    else
      flash[:alert] = t('dri.flash.alert.read_permission')
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

    update_object_status if can_change_status?

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

  def build_show_json
    json     = @object.as_json
    solr_doc = SolrDocument.find(@object.alternate_id)

    json['licence']          = DRI::Formatters::Json.licence(solr_doc)
    json['copyright']        = DRI::Formatters::Json.copyright(solr_doc)
    json['doi']              = DRI::Formatters::Json.dois(solr_doc)
    json['related_objects']  = solr_doc.object_relationships_as_json
    json
  end

  def handle_zip_request
    if current_user
      Resque.enqueue(CreateArchiveJob, params[:id], current_user.email)
      flash[:notice] = t('dri.flash.notice.archiving')
    else
      flash[:alert] = t('dri.flash.alert.archiving_login')
    end
    redirect_back(fallback_location: root_path)
  end

  def doi_published_warning?
    @document.published? && @document.doi.present?
  end

  def assign_governing_collection
    return unless params[:digital_object][:governing_collection_id].present?

    collection = retrieve_object(params[:digital_object][:governing_collection_id])
    @object.governing_collection = collection
  end

  def doi_update_params
    return {} unless doi

    update_params.select { |key, _| doi.metadata_fields.include?(key) }
  end

  def handle_save_failure(error, action)
    case error
    when DRI::SolrBadRequest
      flash[:alert] = t('dri.flash.alert.invalid_object', error: error.details)
    else
      flash[:alert] = t('dri.flash.error.unable_to_persist')
    end
    respond_to do |format|
      format.html { render action: action }
    end
  end

  def render_invalid_object(action)
    flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
    respond_to do |format|
      format.html { render action: action }
    end
  end

  def resolve_governing_collection
    if params[:governing_collection_id].present?
      @governing_collection = retrieve_object!(params[:governing_collection_id])
    else
      after_create_failure(DRI::Exceptions::BadRequest)
    end
  end

  def governing_collection_present?
    @governing_collection.present?
  end

  def build_object_for_create
    if params[:documentation_for].present? && params[:metadata_file].blank?
      create_from_form(:documentation)
    elsif params[:metadata_file].present?
      create_from_upload
    else
      create_from_form
    end

    @object.governing_collection = @governing_collection
  end

  def assign_object_visibility
    @object.visibility = if @object.read_groups_string.present?
                           visibility_label(@object.read_groups_string)
                         else
                           SolrDocument.find(@governing_collection.alternate_id)
                             .ancestor_field('visibility_ssi')
                         end
  end

  def handle_invalid_object_on_create
    flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
    if params[:metadata_file].present?
      after_create_failure(DRI::Exceptions::BadRequest)
    else
      render :new
    end
  end

  def persist_new_object
    result = ObjectSaveService.new(@object).call

    if result.success?
      ObjectPostSaveService.new(@object).call do
        warn_if_has_duplicates(@object)
        record_version_committer(@object, current_user)
        create_reader_group if @object.collection?
      end
      after_create_success(@object, @warnings)
    else
      handle_create_save_failure(result.error)
    end
  rescue DRI::SolrBadRequest => e
    flash[:alert] = t('dri.flash.alert.invalid_object', error: e.details)
    redirect_back(fallback_location: root_path)
  end

  def handle_create_save_failure(error)
    if params[:metadata_file].present?
      after_create_failure(DRI::Exceptions::InternalError)
    else
      flash[:alert] = t('dri.flash.error.unable_to_persist')
      render :new
    end
  end

  def create_from_upload
    xml_ds = XmlDatastream.new
    xml    = xml_ds.load_xml(params[:metadata_file])

    if params[:documentation_for]
      unless xml_ds.metadata_standard == :qdc
        flash[:alert] = t('dri.flash.alert.invalid_object', error: 'documentation objects must use Qualified Dublin Core')
        after_create_failure(DRI::Exceptions::BadRequest)
        return
      end
      @object = build_documentation_object
    else
      @object = DRI::DigitalObject.with_standard(xml_ds.metadata_standard)
    end

    @object.depositor = current_user.to_s
    @object.assign_attributes(create_params)
    @object.update_metadata(xml)
  end

  def create_from_form(type = :qdc)
    @object = if type == :documentation
                build_documentation_object
              else
                DRI::DigitalObject.with_standard(type)
              end

    @object.depositor = current_user.to_s
    @object.assign_attributes(create_params)
  end

  def build_documentation_object
    obj = DRI::Documentation.new
    documented = retrieve_object(params[:documentation_for])
    obj.documentation_for = documented if documented
    obj.read_groups = ['public']
    obj
  end

  def create_reader_group
    group = UserGroup::Group.new(
      name:        @object.alternate_id,
      description: "Default Reader group for collection #{@object.alternate_id}"
    )
    group.reader_group = true
    group.save
  end

  def after_create_failure(exception)
    respond_to do |format|
      format.html  { raise exception }
      format.json  { raise exception }
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

  def destroy_solr_only_object
    solr_object = SolrDocument.find(params[:id])
    raise DRI::Exceptions::NotFound, t('dri.views.exceptions.unknown_object') + " ID: #{params[:id]}" unless solr_object

    SolrDocument.delete(params[:id])
    solr_object.collection_id
  end

  def destroy_full_object
    raise Blacklight::AccessControls::AccessDenied.new(
      t('dri.flash.alert.delete_permission'), :delete, ''
    ) if @object.status == 'published' && !current_user.is_admin?

    @object.increment_version
    run_destroy_preservation
    record_version_committer(@object, current_user, 'delete')

    collection_id = @object.governing_collection.alternate_id
    @object.destroy
    collection_id
  end

  def run_destroy_preservation
    preservation = Preservation::Preservator.new(@object)

    if @object.status == 'published'
      assets = @object.generic_files.map { |gf| "#{gf.alternate_id}_#{gf.label}" }
      preservation.update_manifests(
        deleted: { 'content' => assets, 'metadata' => ['descMetadata.xml'] }
      )
    else
      preservation.remove_moab_dirs
    end
  end

  def can_change_status?
    @object.status != 'published' || current_user.is_admin?
  end

  def update_object_status
    @object.status       = params[:status]
    @object.published_at = Time.now.utc.iso8601 if @object.published_at.nil? && params[:status] == 'published'
    @object.increment_version
    @object.save

    Preservation::Preservator.new(@object).preserve
    record_version_committer(@object, current_user, @object.status)
    set_ancestors_reviewed if params[:status] == 'reviewed'
  end

  def set_ancestors_reviewed
    collection = @object.governing_collection

    until collection.root_collection?
      if collection.status == 'draft'
        collection.status = 'reviewed'
        collection.increment_version
        collection.save

        Preservation::Preservator.new(collection).preserve
        record_version_committer(collection, current_user, collection.status)
      end

      collection = collection.governing_collection
    end
  end

  def downcase_permissions_params
    return if params[:digital_object].blank?

    %i[read_users_string edit_users_string].each do |key|
      params[:digital_object][key] = params[:digital_object][key].to_s.downcase if params[:digital_object][key].present?
    end
  end

  def metadata_standard
    @object.descMetadata.class.to_s.downcase.split('::').last
  end

  def sub_collection_param?
    params[:is_sub_collection].present? && params[:is_sub_collection] == 'true'
  end

  def reorder_types
    return if PrimaryTypes::TYPES.include?(@object.type.first)

    primary_type_index = nil
    object_type_index  = nil

    @object.type.each_with_index do |x, x_index|
      y_index = PrimaryTypes::TYPES.index { |y| y.downcase == x.downcase.delete(' ') }
      next unless y_index

      primary_type_index = y_index
      object_type_index  = x_index
      break
    end

    return unless primary_type_index && object_type_index

    primary_type = PrimaryTypes::TYPES[primary_type_index]
    object_types = @object.type.to_a
    object_types.delete_at(object_type_index)
    @object.type = [primary_type] + object_types
  end
end