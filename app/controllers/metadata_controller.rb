require 'metadata_helpers'

#
# Creates, updates, or retrieves, the descMetadata datastream for an object
# 
class MetadataController < CatalogController

  before_filter :authenticate_user!, :only => [:update]

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

    if @object && @object.datastreams.keys.include?("descMetadata")
       render :xml => @object.datastreams["descMetadata"].content
       return
    end

    render :text => "Unable to load metadata"
  end

  # Replaces the current descMetadata datastream with the contents of the uploaded XML file.
  #
  #
  def update 
    enforce_permissions!("update",params[:id])

    if !params.has_key?(:metadata_file) || params[:metadata_file].nil?
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
    else
      xml = MetadataHelpers.load_xml(params[:metadata_file])

      @object = retrieve_object! params[:id]

      unless can? :update, @object
        raise Hydra::AccessDenied.new(t('dri.flash.alert.edit_permission'), :edit, "")
      end
  
      if @object == nil
        flash[:notice] = t('dri.flash.notice.specify_object_id')
      else
        MetadataHelpers.set_metadata_datastream(@object, xml)
        MetadataHelpers.checksum_metadata(@object)
        check_for_duplicates(@object)

        begin
          raise Exceptions::InternalError unless @object.datastreams["descMetadata"].save
        rescue RuntimeError => e
          logger.error "Could not save descMetadata for object #{@object.id}: #{e.message}"
          raise Exceptions::InternalError
        end

        if @object.valid?
          begin
            raise Exceptions::InternalError unless @object.save
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
