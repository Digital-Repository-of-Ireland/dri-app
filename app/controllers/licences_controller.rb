class LicencesController < ApplicationController
  before_action :authenticate_user_from_token!, except: [:index]
  before_action :authenticate_user!, except: [:index]
  before_action :admin?, except: [:index]
  before_action :read_only, except: [:index]

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
    create_or_modify_licence

    respond_to do |format|
      format.html do
        flash[:notice] = t('dri.flash.notice.licence_created')
        @licences = Licence.all
        render action: 'index'
      end
    end
  end

  # Update existing licence
  def update
    @licence = Licence.find(params[:id])
    create_or_modify_licence

    respond_to do |format|
      format.html do
        flash[:notice] = t('dri.flash.notice.licence_updated')
        @licences = Licence.all
        render action: 'index'
      end
    end
  end

  private

    def admin?
      raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless current_user.is_admin?
    end

    def create_or_modify_licence
      @licence.name = params[:licence][:name]

      if params[:licence][:logo].present? && params[:licence][:logo] =~ URI.regexp
        @licence.logo = params[:licence][:logo]
      end

      if params[:licence][:url].present? && params[:licence][:url] =~ URI.regexp
        @licence.url = params[:licence][:url]
      end

      if params[:licence][:description].present?
        @licence.description = params[:licence][:description]
      end

      @licence.save
    end
end
