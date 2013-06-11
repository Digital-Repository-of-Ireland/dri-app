# Controller for Digital Objects
#

require 'stepped_forms'
require 'checksum'

class ObjectsController < AssetsController
  include SteppedForms

  before_filter :authenticate_user!, :only => [:create, :new, :edit, :update]

  # Edits an existing model.
  #
  def edit
    enforce_permissions!("edit",params[:id]) 
    @object = retrieve_object(params[:id])
    respond_to do |format|
      format.html
      format.json  { render :json => @object }
    end
  end

  # Updates the attributes of an existing model.
  #
  #TODO:: Cleanup method
  def update
    if params[:dri_model][:manager_groups_string].present? or params[:dri_model][:manager_users_string].present?
      enforce_permissions!("manage_collection", params[:id])
    else
      enforce_permissions!("edit",params[:id])
    end

    @object = retrieve_object(params[:id])

    if params[:dri_model][:governing_collection_id].present?
      collection = Collection.find(params[:dri_model][:governing_collection_id])
      @object.governing_collection = collection
    end

    if params[:dri_model][:private_metadata].present?
      selected_level = params[:dri_model].delete(:private_metadata)
      case selected_level
      when "radio_public"
        params[:dri_model][:private_metadata] = "0"
      when "radio_private"
        params[:dri_model][:private_metadata] = "1"
      when "radio_inherit"
        params[:dri_model][:private_metadata] = "-1"
      end
    end
    
    if params[:dri_model][:master_file].present?
      selected_level = params[:dri_model].delete(:master_file)
      case selected_level
      when "radio_public"
        params[:dri_model][:master_file] = "1"
      when "radio_private"
        params[:dri_model][:master_file] = "0"
      when "radio_inherit"
        params[:dri_model][:master_file] = "-1"
      end
    end

    @object.update_attributes(params[:dri_model])

    checksum_metadata(@object)
    check_for_duplicates(@object)

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.metadata_updated')
      format.html  { render :action => "edit" }
      format.json  { render :json => @object }
    end
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    if params[:dri_model][:governing_collection].present? && !params[:dri_model][:governing_collection].blank?
      params[:dri_model][:governing_collection] = Collection.find(params[:dri_model][:governing_collection])
    else
      params[:dri_model].delete(:governing_collection)
    end

    enforce_permissions!("create_digital_object",params[:dri_model][:governing_collection])

    if params[:dri_model][:type].present? && !params[:dri_model][:type].blank?
      type = params[:dri_model][:type]
      params[:dri_model].delete(:type)

      @object = DRI::Model::DigitalObject.construct(type.to_sym, params[:dri_model])
    else
      flash[:alert] = t('dri.flash.error.no_type_specified')
      raise Exceptions::BadRequest, t('dri.views.exceptions.no_type_specified')
      return
    end

    #Adds user as depositor and also grants edit permission (Clears permissions for current_user)
    @object.apply_depositor_metadata(current_user.to_s)

    checksum_metadata(@object)
    check_for_duplicates(@object)

    if @object.valid? && @object.save

      buckets = S3Interface::Bucket.new()
      buckets.create_bucket(@object.pid.sub('dri:', ''))

      respond_to do |format|
        format.html { flash[:notice] = t('dri.flash.notice.digital_object_ingested')
          redirect_to :controller => "catalog", :action => "show", :id => @object.id
        }
        format.json { render :json => "{\"pid\": \"#{@object.id}\"}", :location => catalog_url(@object_fedora), :status => :created }
      end
    else
      respond_to do |format|
        format.html {
          flash[:alert] = @object.errors.messages.values.to_s
          raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata_input')
          return
        }
        format.json {
          raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata_input')
          render :json => @object.errors
        }
      end
    end

  end

  private

    def checksum_metadata(object)
      if object.datastreams.keys.include?("descMetadata")
        xml = object.datastreams["descMetadata"].content

         object.metadata_md5 = Checksum.md5_string(xml)
      end
    end

end

