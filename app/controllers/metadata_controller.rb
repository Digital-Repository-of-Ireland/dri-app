TITLES = {
  'qualifieddc' => 'Dublin Core Metadata',
  'record' => 'MARC Metadata',
  'mods' => 'MODS Metadata',
  'ead' => 'EAD Metadata',
  'c' => 'EAD Metadata',
  'RDF' => 'Dublin Core Metadata (in RDF/XML)'
}.freeze

#
# Creates, updates, or retrieves, the descMetadata datastream for an object
#
class MetadataController < CatalogController
  include DRI::MetadataBehaviour

  before_action :authenticate_user_from_token!, except: :show
  before_action :authenticate_user!, except: :show
  before_action :read_only, except: :show

  def actor
    @actor ||= DRI::Object::Actor.new(@object, current_user)
  end

  # Renders the metadata XML stored in the descMetadata datastream.
  #
  #
  def show
    enforce_permissions!('show_digital_object', params[:id])
    begin
      @object = retrieve_object! params[:id]
    rescue ActiveFedora::ObjectNotFoundError
      render xml: { error: 'Not found' }, status: 404
      return
    end

    if @object && @object.attached_files.key?(:descMetadata)
      respond_to do |format|
        format.xml do
          data = if @object.attached_files.key?(:fullMetadata) && @object.attached_files[:fullMetadata].content
                   @object.attached_files[:fullMetadata].content
                 else
                   @object.attached_files[:descMetadata].content
                 end
          send_data(data, filename: "#{@object.id}.xml")
        end
        format.js do
          xml_data = @object.attached_files[:descMetadata].content
          xml = Nokogiri::XML(xml_data)
          xslt_data = File.read("app/assets/stylesheets/#{xml.root.name}.xsl")
          xslt = Nokogiri::XSLT(xslt_data)
          styled_xml = xslt.transform(xml)

          @title = TITLES[xml.root.name]
          @display_xml = styled_xml.to_html
        end
      end

      return
    end

    render text: 'Unable to load metadata'
  end

  # Replaces the current descMetadata datastream with the contents of the uploaded XML file.
  def update
    enforce_permissions!('update', params[:id])

    param = params[:xml].presence || params[:metadata_file].presence

    if param
      xml = load_xml(param)
    else
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
      redirect_to controller: 'catalog', action: 'show', id: params[:id]
      return
    end

    @object = retrieve_object!(params[:id])
    @errors = nil

    unless can? :update, @object
      raise Hydra::AccessDenied.new(t('dri.flash.alert.edit_permission'), :edit, '')
    end

    @object.update_metadata xml
    if @object.valid?
      checksum_metadata(@object)
      warn_if_duplicates

      begin
        raise Exceptions::InternalError unless @object.attached_files[:descMetadata].save
      rescue RuntimeError => e
        logger.error "Could not save descMetadata for object #{@object.id}: #{e.message}"
        raise Exceptions::InternalError
      end

      begin
        raise Exceptions::InternalError unless @object.save

        actor.version_and_record_committer
        flash[:notice] = t('dri.flash.notice.metadata_updated')
      rescue RuntimeError => e
        logger.error "Could not save object #{@object.id}: #{e.message}"
        raise Exceptions::InternalError
      end
    else
      flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
      @errors = @object.errors.full_messages.inspect
    end

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'show', id: params[:id] }
      format.json { render json: @object }
      format.text do
        response = if @errors
                     t('dri.flash.alert.invalid_object', error: @errors)
                   else
                     t('dri.flash.notice.metadata_updated')
                   end

        render text: response
      end
    end
  end
end
