require 'metadata_helpers'

#
# Creates, updates, or retrieves, the descMetadata datastream for an object
#
class MetadataController < CatalogController
  before_filter :authenticate_user_from_token!, except: :show
  before_filter :authenticate_user!, except: :show

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
        format.xml { render xml: (@object.attached_files.key?(:fullMetadata) && @object.attached_files[:fullMetadata].content) ?
                                @object.attached_files[:fullMetadata].content : @object.attached_files[:descMetadata].content
        }
        format.html {
          xml_data = @object.attached_files[:descMetadata].content
          xml = Nokogiri::XML(xml_data)
          xslt_data = File.read("app/assets/stylesheets/#{xml.root.name}.xsl")
          xslt = Nokogiri::XSLT(xslt_data)
          styled_xml = xslt.transform(xml)
          render text: styled_xml.to_html
        }
      end

      return
    end

    render text: 'Unable to load metadata'
  end

  # Replaces the current descMetadata datastream with the contents of the uploaded XML file.
  def update
    enforce_permissions!('update', params[:id])

    unless params[:metadata_file].present?
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
      redirect_to controller: 'catalog', action: 'show', id: params[:id]
      return
    end
    xml = MetadataHelpers.load_xml(params[:metadata_file])

    @object = retrieve_object! params[:id]

    unless can? :update, @object
      raise Hydra::AccessDenied.new(t('dri.flash.alert.edit_permission'), :edit, '')
    end

    @object.update_metadata xml
    unless @object.valid?
      flash[:alert] = t('dri.flash.alert.invalid_object', :error => @object.errors.full_messages.inspect)
      redirect_to controller: 'catalog', action: 'show', id: params[:id]
      return
    end

    MetadataHelpers.checksum_metadata(@object)
    warn_if_duplicates

    begin
      raise Exceptions::InternalError unless @object.attached_files[:descMetadata].save
    rescue RuntimeError => e
      logger.error "Could not save descMetadata for object #{@object.id}: #{e.message}"
      raise Exceptions::InternalError
    end
    
    @object.object_version = (@object.object_version.to_i+1).to_s


    begin
      raise Exceptions::InternalError unless @object.save

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(false, false, ['descMetadata','properties'])

      actor.version_and_record_committer
      flash[:notice] = t('dri.flash.notice.metadata_updated')
    rescue RuntimeError => e
      logger.error "Could not save object #{@object.id}: #{e.message}"
      raise Exceptions::InternalError
    end

    redirect_to controller: 'catalog', action: 'show', id: params[:id]
  end
end
