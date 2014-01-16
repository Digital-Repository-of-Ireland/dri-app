class InstitutesController < ApplicationController

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

    @institutes = Institute.find(:all)
    render :partial => 'shared/institute_list'
  end

  def associate
    # save the institute name to the properties datastream
    collection = ActiveFedora::Base.find(params[:object] ,{:cast => true})
    raise Exception::NotFound unless collection

    institute = Institute.where(:name => params[:institute_name]).first
    raise Exception::NotFound unless institute

    collection.institute << institute.name

    raise Exception::InternalError unless collection.save
    render :partial => "shared/display_institutes", :collection => collection
  end

end
