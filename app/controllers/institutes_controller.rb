class InstitutesController < ApplicationController
  require 'institute_helpers'


  # Get the list of institutes
  def show
    @institutes = Institute.find(:all)
  end


  def new
    @inst = Institute.new
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

    @institutes = Institute.find(:all)

    if params[:object]
      @object = ActiveFedora::Base.find(params[:object], {:cast => true})
    end

    respond_to do |format|
      format.js
    end
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

end
