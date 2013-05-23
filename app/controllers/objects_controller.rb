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
    @document_fedora = retrieve_object(params[:id])
    respond_to do |format|
      format.html
      format.json  { render :json => @document_fedora }
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    @document_fedora = retrieve_object(params[:id])

    if params[:dri_model][:manager_groups_string].present? or params[:dri_model][:manager_users_string].present?
      if cannot? :manage_collection, @document_fedora
        #Should I change to manager? Only time this can happen is malicious or command line?
        raise Hydra::AccessDenied.new(t('dri.flash.alert.edit_permission'), :edit, params[:id])
      end
    end

    if params[:dri_model][:governing_collection_id].present?
      collection = Collection.find(params[:dri_model][:governing_collection_id])
      @document_fedora.governing_collection = collection
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
    #Temp delete embargo [Waiting for hydra bug fix]
    params[:dri_model].delete(:embargo)
    @document_fedora.update_attributes(params[:dri_model])

    checksum_metadata(@document_fedora)
    check_for_duplicates(@document_fedora)

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.metadata_updated')
      format.html  { render :action => "edit" }
      format.json  { render :json => @document_fedora }
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

    unless can? :create_do, params[:dri_model][:governing_collection]
      raise Hydra::AccessDenied.new(t('dri.flash.alert.create_permission'), :create, "")
    end


    if params[:dri_model][:type].present? && !params[:dri_model][:type].blank?
      type = params[:dri_model][:type]
      params[:dri_model].delete(:type)

      @document_fedora = DRI::Model::DigitalObject.construct(type.to_sym, params[:dri_model])
    else
      flash[:alert] = t('dri.flash.error.no_type_specified')
      raise Exceptions::BadRequest, t('dri.views.exceptions.no_type_specified')
      return
    end

    #Adds user as depositor and also grants edit permission
    @document_fedora.apply_depositor_metadata(current_user.to_s)

    checksum_metadata(@document_fedora)
    check_for_duplicates(@document_fedora)

    if @document_fedora.valid? && @document_fedora.save

      buckets = S3Interface::Bucket.new()
      buckets.create_bucket(@document_fedora.pid.sub('dri:', ''))

      respond_to do |format|
        format.html { flash[:notice] = t('dri.flash.notice.digital_object_ingested')
          redirect_to :controller => "catalog", :action => "show", :id => @document_fedora.id
        }
        format.json { render :json => "{\"pid\": \"#{@document_fedora.id}\"}", :location => catalog_url(@document_fedora), :status => :created }
      end
    else
      respond_to do |format|
        format.html {
          flash[:alert] = @document_fedora.errors.messages.values.to_s
          raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata_input')
          return
        }
        format.json {
          raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata_input')
          render :json => @document_fedora.errors
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

