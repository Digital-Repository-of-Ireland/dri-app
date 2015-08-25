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
    add_or_remove_association
  end
  
    # Dis-associate institute
  def disassociate
    add_or_remove_association(true)
  end

  private

    def add_or_remove_association(delete=false)
      # save the institute name to the properties datastream
      @collection = ActiveFedora::Base.find(params[:object] ,{:cast => true})
      raise Exceptions::NotFound unless @collection

      delete ? delete_association : add_association

      @collection_institutes = Institute.find_collection_institutes(@collection.institute)
      @depositing_institute = @collection.depositing_institute.present? ? Institute.find_by(name: @collection.depositing_institute) : nil
   
      respond_to do |format|
        format.html  { redirect_to :controller => "catalog", :action => "show", :id => @collection.id }
      end
    end

    def add_association
      institute_name = params[:institute_name]

      if(params[:type].present? && params[:type] == "depositing")
        @collection.depositing_institute = institute_name
      else
        @collection.institute = @collection.institute.push( institute_name )
      end

      if @collection.save
        flash[:notice] = institute_name + " " +  t('dri.flash.notice.organisation_added')
      else
        raise Exceptions::InternalError
      end 
    end

    def delete_association
      institute_name = params[:institute_name]

      institutes = @collection.institute
      institutes.delete(institute_name)
      @collection.institute = institutes 

      if @collection.save
        flash[:notice] = institute_name + " " + t('dri.flash.notice.organisation_removed')
      else
        raise Exceptions::InternalError
      end
    end

    def update_params
      params.require(:institute).permit(:name, :logo, :url)
    end

end
