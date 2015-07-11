class InstitutesController < ApplicationController
  require 'institute_helpers'

  before_filter :authenticate_user_from_token!, :except => [:index]
  before_filter :authenticate_user!, :except => [:index]
  before_filter :check_for_cancel, :only => [:create, :update]

  # Was this action canceled by the user?
  def check_for_cancel
    if params[:commit] == "Cancel"
      redirect_to institutions_path
    end
  end
  
  
  # Get the list of institutes
  def index
    @institutes = Institute.all
  end

  def new
    @inst = Institute.new
  end

  def show
    @inst = Institute.find(params[:id])
  end

  # Create a new institute entry
  def create

    @inst = Institute.new

    file_upload = params[:institute][:logo]

    begin
      @inst.add_logo(file_upload, {:name => params[:institute][:name]})
    rescue Exceptions::UnknownMimeType => e
      flash[:alert] = t('dri.flash.alert.invalid_file_type')
    rescue Exceptions::VirusDetected => e
      flash[:error] = t('dri.flash.alert.virus_detected', :virus => e.message)
    rescue Exceptions::InternalError => e
      logger.error "Could not save licence: #{e.message}"
      raise Exceptions::InternalError
    end

    @inst.url = params[:institute][:url]
    @inst.save
    flash[:notice] = t('dri.flash.notice.organisation_created')

    @institutes = Institute.all

    if params[:object]
      @object = ActiveFedora::Base.find(params[:object], {:cast => true})
    end

    respond_to do |format|
      format.html { redirect_to institutions_url }
    end
  end

  def update
    @inst = Institute.find(params[:id])

    file_upload = params[:institute][:logo]

    begin
      @inst.add_logo(file_upload, {:name => params[:institute][:name]})
    rescue Exceptions::UnknownMimeType => e
      flash[:alert] = t('dri.flash.alert.invalid_file_type')
    rescue Exceptions::VirusDetected => e
      flash[:error] = t('dri.flash.alert.virus_detected', :virus => e.message)
    rescue Exceptions::InternalError => e
      logger.error "Could not save licence: #{e.message}"
      raise Exceptions::InternalError
    end

    @inst.url = params[:institute][:url]
    @inst.save

    respond_to do |format|
      format.html { redirect_to institute_url(@inst) }
    end
  end

  def edit
    @inst = Institute.find(params[:id])
  end


  # Associate institute
  def associate
    # save the institute name to the properties datastream
    collection = ActiveFedora::Base.find(params[:object] ,{:cast => true})
    raise Exceptions::NotFound unless collection

    institute = Institute.where(:name => params[:institute_name]).first
    raise Exceptions::NotFound unless institute

    collection.institute = collection.institute.push(institute.name)

    raise Exceptions::InternalError unless collection.save

    @object = collection
    @institutes = Institutes.all
    @collection_institutes = InstituteHelpers.get_collection_institutes(collection)
    @depositing_institute = InstituteHelpers.get_depositing_institute(collection)

    respond_to do |format|
      format.js
    end

  end
  
    # Dis-associate institute
  def disassociate
    # remove the institute name from the properties datastream
    collection = ActiveFedora::Base.find(params[:object] ,{:cast => true})
    raise Exceptions::NotFound unless collection

    institute = Institute.where(:name => params[:institute_name]).first
    raise Exceptions::NotFound unless institute
    a = collection.institute
    a.delete(institute.name)
    collection.institute = a 


    raise Exceptions::InternalError unless collection.save

    @object = collection
    @collection_institutes = InstituteHelpers.get_collection_institutes(collection)
    @depositing_institute = InstituteHelpers.get_depositing_institute(collection)

    respond_to do |format|
      format.js
    end

  end


  # Associate depositing institute
  def associate_depositing
    collection = ActiveFedora::Base.find(params[:object] ,{:cast => true})
    raise Exceptions::NotFound unless collection

    institute = Institute.where(:name => params[:institute_name]).first
    raise Exceptions::NotFound unless institute

    collection.depositing_institute = institute.name

    raise Exceptions::InternalError unless collection.save

    @object = collection
    @collection_institutes = InstituteHelpers.get_collection_institutes(collection)
    @depositing_institute = InstituteHelpers.get_depositing_institute(collection)

    respond_to do |format|
      format.js
    end

  end

  private

    def update_params
      params.require(:institute).permit!
    end

end
