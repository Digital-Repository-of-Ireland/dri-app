class LicencesController < ApplicationController

  # Get the list of licences
  def index
    @licences = Licence.all
  end

  # Create new licence
  def new
    @licence = Licence.new
  end

  # Edit an existing licence
  def edit
    @licence = Licence.find(params[:id])
  end

  # Not implemented yet
  def show

  end

  # Not implemented yet as we seed the DB, in the future we will need a
  # management interface for licences
  def create
    @licence = Licence.new
    @licence.name = params[:licence][:name]

    add_logo

    if (params[:licence][:url].present? && params[:licence][:url] =~ URI::regexp)
      @licence.url = params[:licence][:url]
    end

    if params[:licence][:description].present?
      @licence.description = params[:licence][:description]
    end

    @licence.save

    respond_to do |format|
      format.html {
        flash[:notice] = t('dri.flash.notice.licence_created')
        @licences = Licence.all
        render action: 'index'
      }
    end
  end


  # Update existing licence
  def update
    @licence = Licence.find(params[:id])
    @licence.name = params[:licence][:name]

    add_logo

    if params[:licence][:url].present? && params[:licence][:url] =~ URI::regexp
      @licence.url = params[:licence][:url]
    end

    if params[:licence][:description].present?
      @licence.description = params[:licence][:description]
    end

    @licence.save

    respond_to do |format|
      format.html {
        flash[:notice] = t('dri.flash.notice.licence_updated')
        @licences = Licence.all
        render action: 'index'
      }
    end
  end

  private

  def add_logo
    if params[:licence][:logo].present? && params[:licence][:logo] =~ URI::regexp
      @licence.logo = params[:licence][:logo]
    elsif params[:logo_file].present?
      begin
        @licence.add_logo(params[:logo_file], { name: params[:licence][:name] })
      rescue Exceptions::UnknownMimeType
        flash[:alert] = t('dri.flash.alert.invalid_file_type')
      rescue Exceptions::VirusDetected => e
        flash[:error] = t('dri.flash.alert.virus_detected', virus: e.message)
      rescue Exceptions::InternalError => e
        logger.error "Could not save licence: #{e.message}"
        raise Exceptions::InternalError
      end
    end
  end
end
