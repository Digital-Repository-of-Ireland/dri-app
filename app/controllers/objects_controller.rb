# Controller for Digital Objects
#

require 'stepped_forms'
require 'metadata_helpers'
require 'doi/datacite'
require 'sufia/models/jobs/mint_doi_job'
require 'institute_helpers'
include Utils

class ObjectsController < CatalogController
  include SteppedForms

  before_filter :authenticate_user!, :only => [:create, :new, :edit, :update]

  # Edits an existing model.
  #
  def edit
    enforce_permissions!("edit",params[:id])
    @collections = ingest_collections
    @object = retrieve_object!(params[:id])
    respond_to do |format|
      format.html
      format.json  { render :json => @object }
    end
  end

  def show
    enforce_permissions!("show",params[:id])

    @object = retrieve_object!(params[:id])

    respond_to do |format|
      format.html { redirect_to(catalog_url(@object)) }
      format.endnote { render :text => @object.export_as_endnote, :layout => false }
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    update_object_permission_check(params[:batch][:manager_groups_string], params[:batch][:manager_users_string], params[:id])
    @collections = ingest_collections
    @object = retrieve_object!(params[:id])

    if params[:batch][:governing_collection_id].present?
      collection = Batch.find(params[:batch][:governing_collection_id])
      @object.governing_collection = collection
    end

    set_access_permissions(:batch)
    @object.update_attributes(params[:batch])

    #Do for collection?
    MetadataHelpers.checksum_metadata(@object)
    duplicates?(@object)

    mint_doi( @object ) unless DoiConfig.nil?

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.metadata_updated')
      format.html  { render :action => "edit" }
      format.json  { render :json => @object }
    end
  end

  def citation
    enforce_permissions!("show",params[:id])

    @object = retrieve_object!(params[:id])
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    params[:batch][:governing_collection] = Batch.find(params[:batch][:governing_collection]) unless params[:batch][:governing_collection].blank?

    enforce_permissions!("create_digital_object",params[:batch][:governing_collection].pid)

    set_access_permissions(:batch)
    @object = Batch.new

    if request.content_type == "multipart/form-data"
      xml = MetadataHelpers.load_xml(params[:metadata_file])
      MetadataHelpers.set_metadata_datastream(@object, xml)
    end

    @object.depositor = current_user.to_s

    @object.update_attributes params[:batch]

    MetadataHelpers.checksum_metadata(@object)
    duplicates?(@object)

    if @object.valid? && @object.save

      mint_doi( @object ) unless DoiConfig.nil?

      respond_to do |format|
        format.html { flash[:notice] = t('dri.flash.notice.digital_object_ingested')
          redirect_to :controller => "catalog", :action => "show", :id => @object.id
        }
        format.json {
          if  !@warnings.nil?
            response = { :pid => @object.id, :warning => @warnings }
          else
            response = { :pid => @object.id }
          end
          render :json => response, :location => catalog_url(@object), :status => :created }
      end
    else
      respond_to do |format|
        format.html {
          flash[:alert] = t('dri.flash.alert.invalid_object', :error => @object.errors.full_messages.inspect)
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

  def index
    @list = []

    if params.has_key?("objects") && !params[:objects].blank?
      solr_query = ActiveFedora::SolrService.construct_query_for_pids(params[:objects].map{|o| o.values.first})
      result_docs = ActiveFedora::SolrService.query(solr_query)

      if result_docs.empty?
        raise Exceptions::NotFound
      end

      storage = Storage::S3Interface.new

      result_docs.each do | r |
        item = {}
        doc = SolrDocument.new(r)

        # Get metadata
        item['pid'] = doc.id
        item['files'] = []
        item['metadata'] = {}

        ['title','subject','type','rights','language','description','creator',
         'contributor','publisher','date','format','source','temporal_coverage',
         'geographical_coverage','geocode_point','geocode_box','institute',
         'root_collection_id'].each do |field|

          if params['metadata'].blank? || params['metadata'].include?(field)
            value = doc[ActiveFedora::SolrService.solr_name(field, :stored_searchable)]

            if field.eql?("institute")
              item['metadata'][field] = InstituteHelpers.get_institutes_from_solr_doc(doc)
            elsif field.eql?("geocode_point")
              if !value.nil? && !value.blank?
                geojson_points = []
                value.each do |point|
                  geojson_points << dcterms_point_to_geojson(point)
                end
                item['metadata'][field] = geojson_points
              end
            elsif field.eql?("geocode_box")
              if !value.nil? && !value.blank?
                geojson_boxes = []
                value.each do |box|
                  geojson_boxes << dcterms_box_to_geojson(box)
                end
                item['metadata'][field] = geojson_boxes
              end
            else
              item['metadata'][field] = value unless value.nil?
            end
          end
        end

        # Get files
        files_query = "is_part_of_ssim:\"info:fedora/#{doc.id}\""
        files = ActiveFedora::SolrService.query(files_query)

        files.each do |mf|
          file_list = {}
          file_doc = SolrDocument.new(mf)

          if can? :read_master, doc
            url = url_for(file_download_url(doc.id, file_doc.id))
            file_list['masterfile'] = url
          end

          timeout = 60 * 60 * 24 * 30 # 30 days
          surrogates = storage.get_surrogates doc, file_doc, timeout
          surrogates.each do |file,loc|
            file_list[file] = loc
          end

          item['files'].push(file_list)
        end

        @list << item
      end

      storage.close
    else
      logger.error "No objects in params #{params.inspect}"
      raise raise Exceptions::BadRequest
    end

    respond_to do |format|
      format.json  { }
    end
  end


  def related
    if params.has_key?("count") && !params[:count].blank? && numeric?(params[:count])
      count = params[:count]
    else
      count = 3
    end

    if params.has_key?("object") && !params[:object].blank?
      solr_query = ActiveFedora::SolrService.construct_query_for_pids([params[:object]])
      result = ActiveFedora::SolrService.instance.conn.get('select',
                             :params=>{:q=>solr_query, :qt => 'standard',
                                       :mlt => 'true', :'mlt.fl' => 'subject_tesim,subject_tesim',
                                       :'mlt.count' => count, :fl => 'id,score', :'mlt.match.include'=> 'false'})
    end

    # TODO: fixme!
    @related = []
    if result && result['moreLikeThis'] && result['moreLikeThis'].first &&
       result['moreLikeThis'].first[1] && result['moreLikeThis'].first[1]['docs']
      result['moreLikeThis'].first[1]['docs'].each do |item|
        @related << item
      end
    end

    respond_to do |format|
      format.json {}
    end
  end

  def status
    enforce_permissions!("edit",params[:id])

    @object = retrieve_object!(params[:id])

    return if request.get?

    @object.status = params[:status] if params[:status].present?

    if @object.is_collection?
      if params[:update_objects].present? && params[:update_objects].eql?("yes")
        @collection_objects = Batch.find(:collection_id_sim => @object.id)

        unless @collection_objects.nil?
          @collection_objects.each do |o|
            if (o.status.eql?("draft")) && (params[:objects_status].eql?("published"))
              mint_doi = true
            end
 
            o.status = params[:objects_status]
            o.save

            if mint_doi
              mint_doi( o ) unless DoiConfig.nil?
            end
          end
        end
      end
    end

    @object.save

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.metadata_updated')
      format.html  { redirect_to :controller => "catalog", :action => "show", :id => @object.id }
      format.json  { render :json => @object }
    end

  end

  def mint_doi( object )
    if object.status.eql?("published") && object.doi.nil?
      Sufia.queue.push(MintDoiJob.new(object.id))
    end
  end

end

