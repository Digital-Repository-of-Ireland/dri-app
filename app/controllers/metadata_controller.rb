require 'metadata_helpers'

TITLES = { 'qualifieddc' => 'Dublin Core Metadata', 
           'mods' => 'MODS Metadata', 
           'ead' => 'EAD Metadata',
           'c' => 'EAD Metadata',
           'RDF' => 'Dublin Core Metadata (in RDF/XML)'
         }

#
# Creates, updates, or retrieves, the descMetadata datastream for an object
#
class MetadataController < CatalogController
  before_filter :authenticate_user_from_token!, except: :show
  before_filter :authenticate_user!, except: :show
  before_filter :read_only, except: :show

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
        format.xml { 
          data = (@object.attached_files.key?(:fullMetadata) && @object.attached_files[:fullMetadata].content) ?
                                @object.attached_files[:fullMetadata].content : @object.attached_files[:descMetadata].content
          send_data(data, filename: "#{@object.id}.xml")
        }
        format.js {
          xml_data = @object.attached_files[:descMetadata].content
          xml = Nokogiri::XML(xml_data)
          xslt_data = File.read("app/assets/stylesheets/#{xml.root.name}.xsl")
          xslt = Nokogiri::XSLT(xslt_data)
          styled_xml = xslt.transform(xml)

          @title = TITLES[xml.root.name]
          @display_xml = styled_xml.to_html
        }
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
      xml = MetadataHelpers.load_xml(param)
    else
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
      redirect_to controller: 'catalog', action: 'show', id: params[:id]
      return
    end
    
    @object = retrieve_object! params[:id] 
    @errors = []

    unless can? :update, @object
      raise Hydra::AccessDenied.new(t('dri.flash.alert.edit_permission'), :edit, '')
    end

    @object.update_metadata xml
    unless @object.valid?
      flash[:alert] = t('dri.flash.alert.invalid_object', :error => @object.errors.full_messages.inspect)
      @errors << @object.errors.full_messages.inspect 
    else
      MetadataHelpers.checksum_metadata(@object)
      warn_if_duplicates

      begin
        raise Exceptions::InternalError unless @object.attached_files[:descMetadata].save
      rescue RuntimeError => e
        logger.error "Could not save descMetadata for object #{@object.id}: #{e.message}"
        @errors << "Could not save descMetadata for object #{@object.id}: #{e.message}"
        raise Exceptions::InternalError
      end
      
      begin
        raise Exceptions::InternalError unless @object.save

        actor.version_and_record_committer
        flash[:notice] = t('dri.flash.notice.metadata_updated')
      rescue RuntimeError => e
        logger.error "Could not save object #{@object.id}: #{e.message}"
        @errors << "Could not save object #{@object.id}: #{e.message}"
        raise Exceptions::InternalError
      end
    end

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'show', id: params[:id] }
      format.text { 
        response = @errors.empty? ? t('dri.flash.notice.metadata_updated') : @errors.join(',')
        render text: response 
      }
    end
  end

end
