# frozen_string_literal: true
class InstitutesController < ApplicationController
  before_action :authenticate_user_from_token!, except: [:index, :logo]
  before_action :authenticate_user!, except: [:index, :logo]
  before_action :check_for_cancel, only: [:create, :update]
  before_action :admin?, only: [:destroy]
  before_action :manager?, only: [:edit, :update, :show]
  before_action :read_only, except: [:index, :show, :logo]

  # Was this action canceled by the user?
  def check_for_cancel
    return unless params[:commit] == 'Cancel'

    if current_user.is_admin? || params.dig(:institute, :action) == 'new'
      redirect_to workspace_url
    else
      redirect_to manage_users_url
    end
  end

  # Get the list of institutes
  def index
    @institutes = Institute.all.order('name asc')
    @collections = {}
    @institutes.each do |institute|
      @collections[institute.id] = institute.collections.select(&:published?)
    end

    @depositing_institutes = @institutes.select { |i| i.depositing == true }
    @other_institutes = @institutes.select { |i| i.depositing.blank? }
  end

  def new
    @institutes = Institute.all.order('name asc')
    @inst = Institute.new
  end

  def show
    @inst = Institute.find(params[:id])
  end

  def logo
    brand = Institute.find(params[:id]).brand

    send_data(
      brand.file_contents,
      type: brand.content_type,
      filename: brand.filename,
      disposition: 'inline'
    )
  end

  # Create a new institute entry
  def create
    @inst = Institute.new
    @inst.name = params[:institute][:name]
    @inst.url = params[:institute][:url]

    # we need the model persisted before we set the manager and logo
    if @inst.save
      set_manager_settings

      if params[:institute][:logo].present?
        add_logo(params[:institute][:logo])
        flash[:error] = t('dri.flash.error.unable_to_save_logo') unless @inst.save
      end

      flash[:notice] = t('dri.flash.notice.organisation_created')

      respond_to do |format|
        format.html { redirect_to organisation_url(@inst) }
      end
    else
      flash[:error] = t('dri.flash.error.unable_to_save_organisation')
    end
  end

  def destroy
    @institute = Institute.find(params[:id])

    if @institute.collections.size.zero?
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

    add_logo(params[:institute][:logo]) if params[:institute][:logo].present?

    @inst.url = params[:institute][:url]
    @inst.name = params[:institute][:name]

    if current_user.is_admin?
      @inst.depositing = params[:institute][:depositing] if params[:institute][:depositing].present?
      @inst.manager = params[:institute][:manager] if params[:institute][:manager].present?
    end
    @inst.save

    respond_to do |format|
      format.html { redirect_to organisation_url(@inst) }
    end
  end

  def edit
    @inst = Institute.find(params[:id])
  end

  # Associate institute
  def associate
    manage_association do
      add_association
    end
  end

  # Dis-associate institute
  def disassociate
    manage_association do
      delete_association
    end
  end

  def set
    enforce_permissions!('manage_collection', params[:id])
    @collection = retrieve_object!(params[:id])

    @collection.institute = if params[:institutes].present?
                              params[:institutes].select { |i| i.is_a? String }
                            else
                              nil
                            end

    if params[:depositing_organisation].present? && params[:depositing_organisation] != 'not_set'
      @collection.depositing_institute =  params[:depositing_organisation] 
    else
      if !@collection.published? || current_user.is_admin?
        @collection.depositing_institute = nil
      end
    end

    @collection.increment_version

    raise DRI::Exceptions::InternalError unless @collection.save

    version_and_preserve

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.organisations_set')
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @collection.alternate_id }
    end
  end

  private

  def add_logo(file_upload)
    @inst.add_logo(file_upload)
  rescue DRI::Exceptions::UnknownMimeType
    flash[:alert] = t('dri.flash.alert.invalid_file_type')
  rescue DRI::Exceptions::VirusDetected => e
    flash[:error] = t('dri.flash.alert.virus_detected', virus: e.message)
  rescue DRI::Exceptions::InternalError => e
    logger.error "Could not save licence: #{e.message}"
    raise DRI::Exceptions::InternalError
  end

  def manage_association
    # save the institute name to the properties datastream
    @collection = retrieve_object(params[:object])
    raise DRI::Exceptions::NotFound unless @collection

    @collection.increment_version

    yield

    @collection_institutes = Institute.where(name: @collection.institute.flatten).to_a
    @depositing_institute = @collection.depositing_institute.present? ? Institute.find_by(name: @collection.depositing_institute) : nil

    version_and_preserve

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @collection.alternate_id }
    end
  end

  def add_association
    institute_name = params[:institute_name]
    notice = if params[:type].present? && params[:type] == 'depositing'
               @collection.depositing_institute = institute_name
               "#{institute_name} #{t('dri.flash.notice.organisation_depositor')}"
             else
               @collection.institute = @collection.institute.push(institute_name)
               "#{institute_name} #{t('dri.flash.notice.organisation_added')}"
             end
    raise DRI::Exceptions::InternalError unless @collection.save

    flash[:notice] = notice
  end

  def delete_association
    institute_name = params[:institute_name]
    @collection.institute = @collection.institute - [institute_name]
    raise DRI::Exceptions::InternalError unless @collection.save

    flash[:notice] = "#{institute_name} #{t('dri.flash.notice.organisation_removed')}"
  end

  def admin?
    raise Blacklight::AccessControls::AccessDenied, t('dri.views.exceptions.access_denied') unless current_user.is_admin?
  end
  
  # User must be the organisation manager assigned to the organisation
  def manager?
    return true if current_user.is_admin?
    raise Blacklight::AccessControls::AccessDenied, t('dri.views.exceptions.access_denied') unless current_user.is_om?

    i = Institute.find(params[:id])
    raise Blacklight::AccessControls::AccessDenied, t('dri.views.exceptions.access_denied') unless i&.org_manager == current_user
  end

  def om?(user)
    UserGroup::User.find_by(email: user)&.is_om?
  end
  
  def set_manager_settings
    return unless current_user.is_admin?
    return unless params[:institute][:depositing].present? || params[:institute][:manager].present?
      
    @inst.depositing = params[:institute][:depositing] if params[:institute][:depositing].present?
    
    if params[:institute][:manager].present? && om?(params[:institute][:manager])
      @inst.manager = params[:institute][:manager]
    else
      flash[:error] = t('dri.flash.error.user_must_be_om')
    end
    flash[:error] = t('dri.flash.error.unable_to_set_manager') unless @inst.save
  end

  def version_and_preserve
    # Do the preservation actions
    VersionCommitter.create(version_id: @collection.object_version, obj_id: @collection.alternate_id, committer_login: current_user.to_s)

    preservation = Preservation::Preservator.new(@collection)
    preservation.preserve
  end

  def update_params
    params.require(:institute).permit(:name, :logo, :url, :depositing, :manager, :action)
  end
end
