require 'metadata_helpers'

#
# Creates, updates, or retrieves, the descMetadata datastream for an object
# 
class MetadataController < CatalogController

  before_filter :authenticate_user_from_token!, :only => [:update]
  before_filter :authenticate_user!, :only => [:update]

  def actor
    @actor ||= DRI::Object::Actor.new(@object, current_user)
  end

  # Renders the metadata XML stored in the descMetadata datastream.
  # 
  #
  def show
    enforce_permissions!("show_digital_object", params[:id])
    begin 
      @object = retrieve_object! params[:id]
    rescue ActiveFedora::ObjectNotFoundError => e
      render :xml => { :error => 'Not found' }, :status => 404
      return
    end

    if @object && @object.attached_files.key?(:descMetadata)
      respond_to do |format|
        format.xml { render :xml => (@object.attached_files.key?(:fullMetadata) && !@object.attached_files[:fullMetadata].content.nil?) ?
                                @object.attached_files[:fullMetadata].content : @object.attached_files[:descMetadata].content
        }
        format.html  { 
          xml_data = @object.attached_files[:descMetadata].content
          xml = Nokogiri::XML(xml_data)
          xslt_data = File.read("app/assets/stylesheets/#{xml.root.name}.xsl")
          xslt = Nokogiri::XSLT(xslt_data)
          styled_xml = xslt.transform(xml)
          render :text => styled_xml.to_html
        }
      end

      return
    end

    render :text => "Unable to load metadata"
  end

  # Replaces the current descMetadata datastream with the contents of the uploaded XML file.
  #
  #
  def update 
    enforce_permissions!("update",params[:id])

    unless params[:metadata_file].present?
      flash[:notice] = t('dri.flash.notice.specify_valid_file') 
    else
      xml = MetadataHelpers.load_xml(params[:metadata_file])

      @object = retrieve_object! params[:id]

      unless can? :update, @object
        raise Hydra::AccessDenied.new(t('dri.flash.alert.edit_permission'), :edit, "")
      end
  
      if @object.nil?
        flash[:notice] = t('dri.flash.notice.specify_object_id')
      else
        @object.update_metadata xml
        MetadataHelpers.checksum_metadata(@object)
        duplicates?(@object)

        begin
          raise Exceptions::InternalError unless @object.attached_files[:descMetadata].save
        rescue RuntimeError => e
          logger.error "Could not save descMetadata for object #{@object.id}: #{e.message}"
          raise Exceptions::InternalError
        end

        if @object.valid?
          begin
            raise Exceptions::InternalError unless @object.save
           
            actor.version_and_record_committer
 
          rescue RuntimeError => e
            logger.error "Could not save object #{@object.id}: #{e.message}"
            raise Exceptions::InternalError
          end

          flash[:notice] = t('dri.flash.notice.metadata_updated')
        end
      end
    end

    redirect_to :controller => "catalog", :action => "show", :id => params[:id]
  end

end
