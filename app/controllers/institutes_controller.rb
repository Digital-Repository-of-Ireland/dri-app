class InstitutesController < ApplicationController
  before_action :authenticate_user_from_token!, except: [:index, :logo]
  before_action :authenticate_user!, except: [:index, :logo]
  before_action :check_for_cancel, only: [:create, :update]
  before_action :admin?, only: [:edit, :update, :destroy]
  before_action :read_only, except: [:index, :show, :logo]

  # Was this action canceled by the user?
  def check_for_cancel
    redirect_to organisations_path if params[:commit] == 'Cancel'
  end

  # Get the list of institutes
  def index
    @institutes = Institute.all.order('name asc')
    @collections = {}
    @institutes.each do |institute|
      @collections[institute.id] = institute_collections(institute[:name])
    end
  end

  def new
    @inst = Institute.new
  end

  def show
    @inst = Institute.find(params[:id])
  end

  def logo
    @brand = Institute.find(params[:id]).brand

    send_data(
      @brand.file_contents,
      type: @brand.content_type,
      filename: @brand.filename,
      disposition: 'inline'
    )
  end

  # Create a new institute entry
  def create
    @inst = Institute.new

    add_logo

    @inst.url = params[:institute][:url]
    if current_user.is_admin?
      @inst.depositing = params[:institute][:depositing]
    else
      @inst.depositing = false
    end
    @inst.save
    flash[:notice] = t('dri.flash.notice.organisation_created')

    @object = ActiveFedora::Base.find(params[:object], cast: true) if params[:object]

    respond_to do |format|
      format.html { redirect_to organisations_url }
    end
  end

  def destroy
    @institute = Institute.find(params[:id])

    if institute_collections(@institute[:name]).size.zero?
      @institute.delete
    else
      flash[:error] = t('dri.flash.error.organisation_cannot_be_deleted')
    end

    respond_to do |format|
      format.html { redirect_to organisations_url }
    end
  end

  def update
    @inst = Institute.find(params[:id])

    add_logo

    @inst.url = params[:institute][:url]
    @inst.save

    respond_to do |format|
      format.html { redirect_to organisations_url }
    end
  end

  def edit
    @inst = Institute.find(params[:id])
  end

  # Associate institute
  def associate
    add_or_remove_association
  end

  # Dis-associate institute
  def disassociate
    add_or_remove_association(true)
  end

  def set
    enforce_permissions!('manage_collection', params[:id])
    @collection = retrieve_object!(params[:id])

    institutes = nil
    institutes = params[:institutes].select { |i| i.is_a? String } if params[:institutes].present?

    @collection.institute = institutes

    if params[:depositing_organisation].present?
      @collection.depositing_institute = params[:depositing_organisation] unless params[:depositing_organisation] == 'not_set'
    end

    version = @collection.object_version || '1'
    @collection.object_version = (version.to_i + 1).to_s

    updated = @collection.save

    if updated
      # Do the preservation actions
      preservation = Preservation::Preservator.new(@collection)
      preservation.preserve(false, false, ['properties'])
    else
      raise DRI::Exceptions::InternalError
    end

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.organisations_set')
      format.html { redirect_to controller: 'catalog', action: 'show', id: @collection.id }
    end
  end

  private

    def add_logo
      file_upload = params[:institute][:logo]

      begin
        @inst.add_logo(file_upload, { name: params[:institute][:name] })
      rescue DRI::Exceptions::UnknownMimeType
        flash[:alert] = t('dri.flash.alert.invalid_file_type')
      rescue DRI::Exceptions::VirusDetected => e
        flash[:error] = t('dri.flash.alert.virus_detected', virus: e.message)
      rescue DRI::Exceptions::InternalError => e
        logger.error "Could not save licence: #{e.message}"
        raise DRI::Exceptions::InternalError
      end
    end

    def add_or_remove_association(delete = false)
      # save the institute name to the properties datastream
      @collection = ActiveFedora::Base.find(params[:object], cast: true)
      raise DRI::Exceptions::NotFound unless @collection

      version = @collection.object_version || '1'
      @collection.object_version = (version.to_i + 1).to_s
      delete ? delete_association : add_association

      @collection_institutes = Institute.find_collection_institutes(@collection.institute)
      @depositing_institute = @collection.depositing_institute.present? ? Institute.find_by(name: @collection.depositing_institute) : nil

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@collection)
      preservation.preserve(false, false, ['properties'])

      respond_to do |format|
        format.html { redirect_to controller: 'catalog', action: 'show', id: @collection.id }
      end
    end

    def add_association
      institute_name = params[:institute_name]

      if params[:type].present? && params[:type] == 'depositing'
        @collection.depositing_institute = institute_name
      else
        @collection.institute = @collection.institute.push(institute_name)
      end

      raise DRI::Exceptions::InternalError unless @collection.save

      flash[:notice] = if params[:type].present? && params[:type] == 'depositing'
                         "#{institute_name} #{t('dri.flash.notice.organisation_depositor')}"
                       else
                         "#{institute_name} #{t('dri.flash.notice.organisation_added')}"
                       end
    end

    def delete_association
      institute_name = params[:institute_name]

      institutes = @collection.institute
      institutes.delete(institute_name)
      @collection.institute = institutes

      raise DRI::Exceptions::InternalError unless @collection.save

      flash[:notice] = "#{institute_name} #{t('dri.flash.notice.organisation_removed')}"
    end

    def admin?
      raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless current_user.is_admin?
    end

    def institute_collections(institute)
      solr_query = institute_collections_query(institute)

      ActiveFedora::SolrService.query(
        solr_query,
        defType: 'edismax',
        fq: "-#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"
      )
    end

    def institute_collections_query(institute)
      solr_query = ""
      if !signed_in? || (!current_user.is_admin? && !current_user.is_cm?)
        solr_query = "#{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:published AND "
      end
      solr_query = solr_query + 
                 "#{ActiveFedora.index_field_mapper.solr_name('institute', :stored_searchable, type: :string)}:\"" + institute.mb_chars.downcase + 
                 "\" AND " + "#{ActiveFedora.index_field_mapper.solr_name('type', :stored_searchable, type: :string)}:Collection"

      solr_query
    end

    def update_params
      params.require(:institute).permit(:name, :logo, :url)
    end
end
