#
# Creates, updates, or retrieves, the descMetadata datastream for an object
# 
class MetadataController < AssetsController

  require 'metadata_validator'

  # Renders the metadata XML stored in the descMetadata datastream.
  # 
  #
  def show
    begin 
      @object = retrieve_object params[:id]
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

    if !params.has_key?(:metadata_file) || params[:metadata_file].nil?
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
    else
      xml = load_xml(params[:metadata_file])

      if !MetadataValidator.is_valid_dc?(xml)
        flash[:error] = t('dri.flash.alert.invalid_object', :error => @object.errors.full_messages.inspect)
        raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata')
        return
      else
        @object = retrieve_object params[:id]

        if @object == nil
          flash[:notice] = t('dri.flash.notice.specify_object_id')
        else
          set_metadata_datastream(xml)
          @object.metadata_md5 = Checksum.md5_string(xml)
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
    end

    redirect_to :controller => "catalog", :action => "show", :id => params[:id]
  end

  # Ingests metadata from an XML file to create a new digital object.
  #
  #
  def create

    if !params.has_key?(:metadata_file) || params[:metadata_file].nil?
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
      redirect_to :controller => "ingest", :action => "new"
      return
    end

    @xml = load_xml(params[:metadata_file])

    result, @msg = MetadataValidator.is_valid_dc?(@xml)

    if !result
      flash[:error] = t('dri.flash.error.validation_errors', :error => @msg)
      raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata')
      return
    end
   
    @object = construct_object
    set_metadata_datastream(@xml)
    add_to_collection
    check_for_duplicates(@object)

    @object.apply_depositor_metadata(current_user.to_s)

    save_object

    respond_to do |format|
      format.html {redirect_to :controller => "catalog", :action => "show", :id => @object.id}
      format.json  { 
        if  !@warnings.nil?
          response = { :pid => @object.id, :warning => @warnings }
        else
          response = { :pid => @object.id }
        end
        render :json => response, :location => catalog_url(@object), :status => :created 
      }
    end
      
  end  

  private

    def load_xml(upload)
      if MIME::Types.type_for(upload.original_filename).first.content_type.eql? 'application/xml'
        tmp = upload.tempfile

        begin
          Nokogiri::XML(tmp.read) { |config| config.options = Nokogiri::XML::ParseOptions::STRICT }
        rescue Nokogiri::XML::SyntaxError => e
          flash[:error] = t('dri.flash.alert.invalid_xml', :error => e)
          raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata')
        end
      end
    end

    def construct_object
      if params.has_key?(:type) && params[:type].present?
        DRI::Model::DigitalObject.construct(params[:type].to_sym, params[:dri_model])
      else
        flash[:error] = t('dri.flash.error.no_type_specified')
        raise Exceptions::BadRequest, t('dri.views.exceptions.no_type_specified')
        return
      end    
    end

    def set_metadata_datastream(xml)
      if @object.datastreams.has_key?("descMetadata")
        @object.datastreams["descMetadata"].ng_xml = xml
      else
        ds = @object.load_from_xml(xml)
        @object.add_datastream ds, :dsid => 'descMetadata'
      end

      @object.metadata_md5 = Checksum.md5_string(xml)     
    end

    def add_to_collection
      if params.has_key?(:governing_collection) && !params[:governing_collection].blank?
        begin
          @object.governing_collection = Collection.find(params[:governing_collection])
        rescue ActiveFedora::ObjectNotFoundError => e
          raise Exceptions::BadRequest, t('dri.views.exceptions.unknown_collection')
          return
        end
     end
    end

    def save_object
      if @object.valid?
          begin
            raise Exceptions::InternalError unless @object.save
          rescue RuntimeError => e
            logger.error "Could not save object: #{e.message}"
            raise Exceptions::InternalError
          end

          flash[:notice] = t('dri.flash.notice.digital_object_ingested')
      else
        flash[:error] = t('dri.flash.alert.invalid_object', :error => @object.errors.full_messages.inspect)

        raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata')
        return
      end
    end

end
