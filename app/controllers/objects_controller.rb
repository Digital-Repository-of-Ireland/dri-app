# Controller for Digital Objects
#

require 'stepped_forms'
require 'checksum'

class ObjectsController < CatalogController
  include SteppedForms

  before_filter :authenticate_user!, :only => [:create, :new, :edit, :update]

  # Edits an existing model.
  #
  def edit
    enforce_permissions!("edit",params[:id]) 
    @object = retrieve_object!(params[:id])
    respond_to do |format|
      format.html
      format.json  { render :json => @object }
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    update_object_permission_check(params[:dri_model][:manager_groups_string], params[:dri_model][:manager_users_string], params[:id])

    @object = retrieve_object!(params[:id])

    if params[:dri_model][:governing_collection_id].present?
      collection = Batch.find(params[:dri_model][:governing_collection_id])
      @object.governing_collection = collection
    end

    set_access_permissions(:dri_model)

    @object.update_attributes(params[:dri_model])

    #Do for collection?
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
      params[:dri_model][:governing_collection] = Batch.find(params[:dri_model][:governing_collection])
    else
      params[:dri_model].delete(:governing_collection)
    end

    enforce_permissions!("create_digital_object",params[:dri_model][:governing_collection])

    if params[:dri_model][:type].present? && !params[:dri_model][:type].blank?
      type = params[:dri_model][:type]
      params[:dri_model].delete(:type)

      set_access_permissions(:dri_model)

      @object = Batch.new params[:dri_model]
      @object.object_type = [ type ]
    else
      flash[:alert] = t('dri.flash.error.no_type_specified')
      raise Exceptions::BadRequest, t('dri.views.exceptions.no_type_specified')
      return
    end

    #Adds user as depositor and also grants edit permission (Clears permissions for current_user)
    #@object.apply_depositor_metadata(current_user.to_s)
    # depositor is not submitted as part of the form
    @object.depositor = current_user.to_s 

    checksum_metadata(@object)
    check_for_duplicates(@object)

    if @object.valid? && @object.save

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

