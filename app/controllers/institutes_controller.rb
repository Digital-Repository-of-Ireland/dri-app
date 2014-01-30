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
    @inst.add_logo(file_upload, {:name => params[:institute][:name]})

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

  def associate
    # save the institute name to the properties datastream
    collection = ActiveFedora::Base.find(params[:object] ,{:cast => true})
    raise Exceptions::NotFound unless collection

    institute = Institute.where(:name => params[:institute_name]).first
    raise Exceptions::NotFound unless institute

    collection.institute = collection.institute.push(institute.name)

    raise Exceptions::InternalError unless collection.save

    @collection_institutes = InstituteHelpers.get_collection_institutes(collection)

    respond_to do |format|
      format.js
    end

  end

end
