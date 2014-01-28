class LicencesController < ApplicationController


  # Get the list of licences
  def index
    @licences = Licence.find(:all)
  end


  # Not implemented yet
  def new
    @licence = Licence.new
  end


  # Not implemented yet
  def show

  end

  # Not implemented yet as we seed the DB, in the future we will need a
  # management interface for licences
  def create

    @licence = Licence.new

    file_upload = params[:licence][:logo]
    @licence.add_logo(file_upload, {:name => params[:licence][:name]})

    @licence.url = params[:licence][:url]
    @licence.save

    @licences = Licences.find(:all)

    respond_to do |format|
      format.html
    end
  end

end
