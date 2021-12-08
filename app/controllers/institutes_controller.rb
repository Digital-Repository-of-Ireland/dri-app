# frozen_string_literal: true
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
    @inst.depositing = if current_user.is_admin?
                         params[:institute][:depositing]
                       else
                         false
                       end
    @inst.save
    flash[:notice] = t('dri.flash.notice.organisation_created')

    @object = retrieve_object!(params[:object]) if params[:object]

    respond_to do |format|
      format.html { redirect_to organisations_url }
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

    @collection.institute = params[:institutes].select { |i| i.is_a? String } if params[:institutes].present?
    @collection.depositing_institute = params[:depositing_organisation] if params[:depositing_organisation].present? && params[:depositing_organisation] != 'not_set'
    @collection.increment_version

    raise DRI::Exceptions::InternalError unless @collection.save

    version_and_preserve

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.organisations_set')
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @collection.alternate_id }
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

  def version_and_preserve
    # Do the preservation actions
    VersionCommitter.create(version_id: @collection.object_version, obj_id: @collection.alternate_id, committer_login: current_user.to_s)

    preservation = Preservation::Preservator.new(@collection)
    preservation.preserve
  end

  def update_params
    params.require(:institute).permit(:name, :logo, :url)
  end
end
