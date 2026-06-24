# Controller for the Collection model
#
require 'storage/cover_images'
require 'validators'

class CollectionsController < BaseObjectsController
  include Blacklight::AccessControls::Catalog
  include DRI::Duplicable

  before_action :authenticate_user_from_token!, except: [:cover]
  before_action :authenticate_user!, except: [:cover]
  before_action :authorize_cm!, only: [:new, :create]
  before_action :check_for_cancel, only: [:create, :update, :add_cover_image]
  before_action :read_only, except: [:index, :cover]
  before_action ->(id=params[:id]) { locked(id) }, except: %i[index cover lock new create]

  def check_for_cancel
    return unless params[:commit] == t('dri.views.objects.buttons.cancel')

    if params[:id]
      redirect_to controller: 'my_collections', action: 'show', id: params[:id]
    else
      redirect_to controller: 'workspace', action: 'index'
    end
  end

  def index
    query  = "_query_:\"{!join from=id to=ancestor_id_ssim}manager_access_person_ssim:#{current_user.email}\""
    query += " OR manager_access_person_ssim:#{current_user.email}"

    fq = ["+is_collection_ssi:true"]
    fq << "+#{Solr::SchemaFields.searchable_symbol('isGovernedBy')}:#{params[:governing]}" if params[:governing].present?

    collections = results_to_hash(Solr::Query.new(query, 100, { fq: fq }))

    respond_to { |format| format.json { render json: collections } }
  end

  def new
    @object = DRI::DigitalObject.with_standard(:qdc).tap do |obj|
      obj.apply_depositor_metadata(current_user.to_s)
      obj.manager_users_string    = current_user.to_s
      obj.discover_groups_string  = 'public'
      obj.read_groups_string      = 'public'
      obj.master_file_access      = 'private'
      obj.title                   = ['']
      obj.description             = ['']
      obj.creator                 = ['']
      obj.creation_date           = ['']
      obj.rights                  = ['']
      obj.type                    = ['Collection']
    end

    @deposit_orgs = Institute.where(depositing: true).order('name asc')
    supported_licences
    supported_copyrights

    respond_to { |format| format.html }
  end

  def edit
    enforce_permissions!('manage_collection', params[:id])
    @object = retrieve_object!(params[:id])

    @institutes             = Institute.all
    @inst                   = Institute.new
    @collection_institutes  = Institute.where(name: @object.institute.flatten).to_a
    @depositing_institute   = Institute.find_by(name: @object.depositing_institute) if @object.depositing_institute.present?

    supported_licences
    supported_copyrights

    flash[:alert] = t('dri.flash.alert.doi_published_warning').html_safe if @object.published? && @object.doi.present?

    respond_to { |format| format.html }
  end

  def lock
    raise Blacklight::AccessControls::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless current_user.is_admin?

    @object = retrieve_object!(params[:id])
    raise DRI::Exceptions::BadRequest unless @object.collection?

    if request.post?
      CollectionLock.create(collection_id: @object.root_collection.first)
    elsif request.delete?
      CollectionLock.delete_all("collection_id = '#{@object.root_collection.first}'")
    end

    flash[:notice] = t('dri.flash.notice.updated')
    respond_to { |format| format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id } }
  end

  def update
    enforce_permissions!('manage_collection', params[:id])

    @object      = retrieve_object!(params[:id])
    cover_image  = params[:digital_object]&.delete(:cover_image)
    @institutes  = Institute.all
    @inst        = Institute.new

    supported_licences
    supported_copyrights

    title_changed = update_params['title'].present? && (update_params['title'] != @object.title)

    @object.assign_attributes(update_params)
    unless @object.valid?
      flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
      render :edit and return
    end

    @object.increment_version
    store_cover_image(cover_image) if cover_image.present?

    result = ObjectSaveService.new(@object, doi: doi, doi_params: filtered_doi_params).call

    if result.success?
      ObjectPostSaveService.new(@object).call { record_version_committer(@object, current_user, 'update') }
      result.doi_sync&.enqueue_job(doi)
      update_descendants if title_changed

      flash[:notice] = t('dri.flash.notice.updated')
      respond_to do |format|
        format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
        format.json { render json: @object }
      end
    else
      flash[:alert] = t('dri.flash.error.unable_to_persist')
      respond_to { |format| format.html { render :edit } }
    end
  end

  def add_cover_image
    enforce_permissions!('manage_collection', params[:id])

    @object     = retrieve_object!(params[:id])
    cover_image = params.dig(:digital_object, :cover_image)
    raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.file_not_found') if cover_image.blank?

    @object.increment_version

    if store_cover_image(cover_image) && @object.save
      ObjectPostSaveService.new(@object).call { record_version_committer(@object, current_user, 'update') }
      flash[:notice] = t('dri.flash.notice.updated')
    else
      flash[:error] = t('dri.flash.error.cover_image_not_saved')
    end

    respond_to { |format| format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id } }
  end

  def cover
    enforce_permissions!('show_digital_object', params[:id])

    object    = SolrDocument.find(params[:id])
    cover_url = object&.cover_image

    raise DRI::Exceptions::BadRequest, "#{t('dri.views.exceptions.unknown_object')} ID: #{params[:id]}" if object.blank?
    raise DRI::Exceptions::NotFound if cover_url.blank?

    return if redirect_url(cover_url)

    cover_name = File.basename(URI.parse(cover_url).path)
    cover_file = StorageService.new.surrogate_url(object.id, cover_name)
    raise DRI::Exceptions::NotFound unless cover_file

    response.headers['Accept-Ranges']  = 'bytes'
    response.headers['Content-Length'] = File.size(cover_file).to_s
    send_file cover_file, type: MIME::Types.type_for(cover_name).first.content_type, disposition: 'inline'
  end

  def set_licence
    enforce_permissions!('manage_collection', params[:id])
    super
  end

  def set_copyright
    enforce_permissions!('manage_collection', params[:id])
    super
  end

  def create
    cover_image = params[:digital_object]&.delete(:cover_image)
    from_xml    = params[:metadata_file].present?

    unless (from_xml ? create_from_xml : create_from_form)
      from_xml ? after_create_failure(DRI::Exceptions::BadRequest) : (render :new and return)
    end

    unless @object.valid?
      flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
      from_xml ? after_create_failure(DRI::Exceptions::BadRequest) : (render :new and return)
    end

    unless @object.save
      respond_to do |format|
        format.html { flash[:alert] = t('dri.flash.error.unable_to_persist'); render :new }
        format.json { render json: { error: t('dri.flash.error.unable_to_persist') }, status: 500 }
      end
      return
    end

    store_cover_image(cover_image) if cover_image.present?

    ObjectPostSaveService.new(@object, datastreams: ['descMetadata']).call do
      create_reader_group
      CollectionConfig.create(collection_id: @object.alternate_id, allow_export: true)
      record_version_committer(@object, current_user)
    end

    respond_to do |format|
      format.html do
        flash[:notice] = t('dri.flash.notice.collection_created')
        redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id
      end
      format.json { render json: { id: @object.alternate_id, title: @object.title, description: @object.description }, status: :created }
    end
  end

  def destroy
    enforce_permissions!('manage_collection', params[:id])

    @object = retrieve_object!(params[:id])
    unless current_user.is_admin? || ((can? :manage_collection, @object) && @object.status == 'draft')
      raise Blacklight::AccessControls::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '')
    end

    begin
      delete_collection
      @object.increment_version
      record_version_committer(@object, current_user, 'delete')
      flash[:notice] = t('dri.flash.notice.collection_deleted')
    rescue DRI::Exceptions::ResqueError => e
      flash[:error] = t('dri.flash.alert.error_deleting_collection', error: e.message)
      redirect_to :back and return
    end

    respond_to { |format| format.html { redirect_to controller: 'workspace', action: 'index' } }
  end

  def review
    enforce_permissions!('manage_collection', params[:id])
    @object = retrieve_object!(params[:id])

    return if request.get?
    raise DRI::Exceptions::BadRequest unless @object.collection?

    review_all if params[:apply_all] == 'yes' && @object.governed_items.present?

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
      format.json { render json: json_status_response, status: :accepted }
    end
  end

  def publish
    enforce_permissions!('manage_collection', params[:id])
    @object = retrieve_object!(params[:id])
    raise DRI::Exceptions::BadRequest unless @object.collection?

    begin
      publish_collection
      flash[:notice] = t('dri.flash.notice.collection_publishing')
    rescue Exception => e
      flash[:alert] = @warnings = t('dri.flash.alert.error_publishing_collection', error: e.message)
    end

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.alternate_id }
      format.json { render json: json_status_response, status: :accepted }
    end
  end

  private

    # Stores a cover image for @object. Returns the URL on success, nil on failure.
    def store_cover_image(cover_image)
      url = Storage::CoverImages.validate_and_store(cover_image, @object)
      if url
        @object.cover_image = url
      else
        flash[:error] = t('dri.flash.error.cover_image_not_saved')
      end
      url
    end

    # Filters update_params to only DOI metadata fields, remapping :type -> :resource_type.
    def filtered_doi_params
      return {} unless doi

      update_params
        .select { |key, _| doi.metadata_fields.include?(key) }
        .tap    { |p| p['resource_type'] = p.delete('type') if p.key?('type') }
    end

    # Shared JSON body for review/publish responses.
    def json_status_response
      { id: @object.alternate_id, status: @object.status }.tap do |r|
        r[:warning] = @warnings if @warnings
      end
    end

    def create_from_form
      @object = DRI::DigitalObject.with_standard(:qdc)

      supported_licences
      supported_copyrights
      @object.assign_attributes(create_params.merge(type: 'Collection'))
      @object.visibility = visibility_label(@object.read_groups_string)

      deposit_org = params[:depositing_institute]
      if deposit_org.blank?
        flash[:alert] = t('dri.flash.alert.no_depositing_org')
      elsif !Institute.exists?(depositing: true, name: deposit_org)
        flash[:alert] = t('dri.flash.alert.invalid_depositing_org')
      else
        @object.institute.push(deposit_org)
        @object.depositing_institute = deposit_org
      end

      @object.depositor = current_user.to_s

      unless valid_root_permissions?
        flash[:alert] = t('dri.flash.error.not_created')
        return false
      end

      true
    end

    def create_from_xml
      if params[:metadata_file].blank?
        flash[:notice] = @error = t('dri.flash.notice.specify_valid_file')
        return false
      end

      xml_ds = XmlDatastream.new
      begin
        xml_ds.load_xml(params[:metadata_file])
      rescue DRI::Exceptions::InvalidXML
        flash[:notice] = @error = t('dri.flash.notice.specify_valid_file')
        return false
      rescue DRI::Exceptions::ValidationErrors => e
        flash[:notice] = @error = e.message
        return false
      end

      if xml_ds.metadata_standard.nil?
        flash[:notice] = @error = t('dri.flash.notice.specify_valid_file')
        return false
      end

      @object = DRI::DigitalObject.with_standard(xml_ds.metadata_standard)
      @object.update_metadata(xml_ds.xml)
      checksum_metadata(@object)
      warn_if_has_duplicates(@object)

      if @object.descMetadata.is_a?(DRI::Metadata::EncodedArchivalDescriptionComponent)
        flash[:notice] = @error = t('dri.flash.notice.specify_valid_file')
        return false
      end

      unless @object.collection?
        flash[:notice] = @error = t('dri.flash.notice.specify_collection')
        return false
      end

      @object.apply_depositor_metadata(current_user.to_s)
      @object.manager_users_string   = current_user.to_s
      @object.discover_groups_string = 'public'
      @object.read_groups_string     = 'public'
      @object.visibility             = 'public'
      @object.master_file_access     = 'private'
      @object.ingest_files_from_metadata = params[:ingest_files] if params[:ingest_files].present?

      true
    end

    def create_reader_group
      @group = UserGroup::Group.new(
        name:        @object.alternate_id,
        description: "Default Reader group for collection #{@object.alternate_id}"
      )
      @group.reader_group = true
      @group.save
      @group
    end

    def redirect_url(cover_url)
      return false unless cover_url =~ /\A#{URI.regexp(['http', 'https'])}\z/

      redirect_to force_https(cover_url).to_s, allow_other_host: true
      true
    end

    def force_https(cover_url)
      URI.parse(cover_url).tap { |uri| uri.scheme = 'https' if Rails.env == 'production' }
    end

    def results_to_hash(solr_query)
      [].tap do |collections|
        while solr_query.has_more?
          solr_query.pop.each do |object|
            governing = object[Solr::SchemaFields.searchable_symbol('isGovernedBy')]
            collections << {
              id:                   object['id'],
              collection_title:     object[Solr::SchemaFields.searchable_string('title')],
              governing_collection: governing.present? ? governing.first : 'root'
            }
          end
        end
      end.group_by { |c| c[:governing_collection] }
    end

    def review_all
      Resque.enqueue(ReviewCollectionJob, @object.alternate_id, current_user.id)
      flash[:notice] = t('dri.flash.notice.collection_objects_review')
    rescue Exception => e
      logger.error "Unable to submit status job: #{e.message}"
      flash[:alert] = @warnings = t('dri.flash.alert.error_review_job', error: e.message)
    end

    def update_descendants
      Resque.enqueue(UpdateDescendantsJob, @object.alternate_id)
    rescue Exception => e
      logger.error "Unable to submit update job: #{e.message}"
    end

    def delete_collection
      DRI.queue.push(DeleteCollectionJob.new(@object.alternate_id, current_user.to_s))
    rescue Exception => e
      logger.error "Unable to delete collection: #{e.message}"
      raise DRI::Exceptions::ResqueError, e.message
    end

    def publish_collection
      Resque.enqueue(PublishCollectionJob, @object.alternate_id, current_user.id)
    rescue Exception => e
      logger.error "Unable to submit publish job: #{e.message}"
      raise DRI::Exceptions::ResqueError
    end

    def respond_with_exception(exception)
      respond_to do |format|
        format.html { raise exception }
        format.json { render json: exception.message, status: :bad_request }
      end
    end

    def valid_root_permissions?
      params[:digital_object][:manager_users_string].present? || params[:digital_object][:edit_users_string].present?
    end
end