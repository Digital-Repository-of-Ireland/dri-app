TITLES = {
  'qualifieddc' => 'Dublin Core Metadata',
  'record'      => 'MARC Metadata',
  'mods'        => 'MODS Metadata',
  'ead'         => 'EAD Metadata',
  'c'           => 'EAD Metadata',
  'RDF'         => 'Dublin Core Metadata (in RDF/XML)'
}.freeze

# Creates, updates, or retrieves the descMetadata datastream for an object.
class MetadataController < ApplicationController
  include DRI::Duplicable
  include DRI::Versionable

  before_action :authenticate_user_from_token!, except: :show
  before_action :authenticate_user!,            except: :show
  before_action :read_only,                     except: :show
  before_action ->(id = params[:id]) { locked(id) }, except: :show

  def show
    enforce_permissions!('show_digital_object', params[:id])
    return unless load_object_for_show

    respond_to do |format|
      format.xml { send_metadata_xml }
      format.js  { render_metadata_js }
    end
  end

  def update
    enforce_permissions!('update', params[:id])
    return redirect_to_object(notice: t('dri.flash.notice.specify_valid_file')) unless xml_datastream

    @object = retrieve_object!(params[:id])
    authorize_update!

    @object.update_metadata(xml_datastream.xml)

    if @object.valid?
      handle_valid_update
    else
      @errors = @object.errors.full_messages.inspect
      flash[:alert] = t('dri.flash.alert.invalid_object', error: @errors)
    end

    respond_to_update_formats
  end

  private

  # --- show helpers ---

  def load_object_for_show
    @object = retrieve_object!(params[:id])
    true
  rescue DRI::Exceptions::InternalError
    @title = status_to_message(:internal_server_error)
    false
  rescue DRI::Exceptions::BadRequest
    render xml: { error: 'Not found' }, status: 404
    false
  end

  def send_metadata_xml
    unless object_with_metadata
      render xml: { error: t('dri.views.exceptions.internal_error') }, status: 500
      return
    end

    data = DRI::MetadataPresenter.new(@object).xml_content
    send_data(data, filename: "#{@object.alternate_id}.xml")
  end

  def render_metadata_js
    unless object_with_metadata
      @display_xml = t('dri.views.exceptions.internal_error')
      return
    end

    presenter    = DRI::MetadataPresenter.new(@object)
    @title       = presenter.title
    @display_xml = presenter.styled_html
  end

  def object_with_metadata
    @object && @object.attached_files.key?(:descMetadata)
  end

  # --- update helpers ---

  def xml_datastream
    @xml_datastream ||= begin
      param = params[:xml].presence || params[:metadata_file].presence
      return nil unless param

      ds = XmlDatastream.new
      ds.load_xml(param)
      ds
    end
  end

  def authorize_update!
    unless can?(:update, @object)
      raise Blacklight::AccessControls::AccessDenied.new(
        t('dri.flash.alert.edit_permission'), :edit, ''
      )
    end
  end

  def handle_valid_update
    checksum_metadata(@object)
    warn_if_has_duplicates(@object)

    MetadataUpdateService.new(@object, current_user).call
    record_version_committer(@object, current_user, 'update')
    flash[:notice] = t('dri.flash.notice.metadata_updated')
  rescue DRI::Exceptions::InternalError => e
    flash[:alert] = t('dri.flash.alert.unable_to_persist')
    @errors = e.message
  end

  def respond_to_update_formats
    respond_to do |format|
      format.html { redirect_to_object }
      format.json { render json: @object }
      format.text { render plain: update_response_text }
    end
  end

  def redirect_to_object(notice: nil)
    flash[:notice] = notice if notice
    redirect_to controller: 'my_collections', action: 'show', id: params[:id]
  end

  def update_response_text
    if @errors
      t('dri.flash.alert.invalid_object', error: @errors)
    else
      t('dri.flash.notice.metadata_updated')
    end
  end
end