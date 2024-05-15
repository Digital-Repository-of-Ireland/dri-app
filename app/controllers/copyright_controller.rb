class CopyrightsController < ApplicationController
  before_action :authenticate_user_from_token!, except: [:index]
  before_action :authenticate_user!, except: [:index]
  before_action :admin?, except: [:index]
  before_action :read_only, except: [:index]

  # Get the list of copyrights
  def index
    @copyrights = Copyright.all
  end

  # Create new copyright
  def new
    @copyright = Copyright.new
  end

  # Edit an existing copyright
  def edit
    @copyright = Copyright.find(params[:id])
  end

  # Not implemented yet
  def show
  end

  # Not implemented yet as we seed the DB, in the future we will need a
  # management interface for copyrights
  def create
    @copyright = Copyright.new
    create_or_modify_copyright

    respond_to do |format|
      format.html do
        flash[:notice] = t('dri.flash.notice.copyright_created')
        @copyrights = Copyright.all
        render action: 'index'
      end
    end
  end

  # Update existing copyright
  def update
    @copyright = Copyright.find(params[:id])
    create_or_modify_copyright

    respond_to do |format|
      format.html do
        flash[:notice] = t('dri.flash.notice.copyright_updated')
        @copyrights = Copyright.all
        render action: 'index'
      end
    end
  end

  private

    def admin?
      raise Blacklight::AccessControls::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless current_user.is_admin?
    end

    def create_or_modify_copyright
      @copyright.name = params[:copyright][:name]

      if params[:copyright][:logo].present? && params[:copyright][:logo] =~ URI.regexp
        @copyright.logo = params[:copyright][:logo]
      end

      if params[:copyright][:url].present? && params[:copyright][:url] =~ URI.regexp
        @copyright.url = params[:copyright][:url]
      end

      if params[:copyright][:description].present?
        @copyright.description = params[:copyright][:description]
      end

      @copyright.save
    end
end
