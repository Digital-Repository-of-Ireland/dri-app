# Controller for Digital Objects
#
require 'solr/query'
require 'preservation/preservator'

include Utils

class ObjectsController < BaseObjectsController

  before_filter :authenticate_user_from_token!, except: [:show, :citation]
  before_filter :authenticate_user!, except: [:show, :citation]

  DEFAULT_METADATA_FIELDS = ['title','subject','creation_date','published_date','type','rights','language','description','creator',
       'contributor','publisher','date','format','source','temporal_coverage',
       'geographical_coverage','geocode_point','geocode_box','institute',
       'root_collection_id'].freeze

  # Displays the New Object form
  #
  def new
    @collection = params[:collection]

    @object = DRI::Batch.with_standard :qdc
    @object.creator = [""]

    supported_licences()
  end


  # Edits an existing model.
  #
  def edit
    enforce_permissions!("edit",params[:id])

    supported_licences()
    
    @object = retrieve_object!(params[:id])
    @object.creator = [""] unless @object.creator[0]
    
    respond_to do |format|
      format.html
      format.json  { render :json => @object }
    end
  end

  def show
    enforce_permissions!("show_digital_object",params[:id])

    @object = retrieve_object!(params[:id])

    respond_to do |format|
      format.html { redirect_to(catalog_url(@object.id)) }
      format.endnote { render :text => @object.export_as_endnote, :layout => false }
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    enforce_permissions!("edit", params[:id])

    params[:batch][:read_users_string] = params[:batch][:read_users_string].to_s.downcase
    params[:batch][:edit_users_string] = params[:batch][:edit_users_string].to_s.downcase
    
    supported_licences()

    @object = retrieve_object!(params[:id])

    if params[:batch][:governing_collection_id].present?
      collection = DRI::Batch.find(params[:batch][:governing_collection_id])
      @object.governing_collection = collection
    end

    doi.update_metadata(params[:batch].select{ |key, value| doi.metadata_fields.include?(key) }) if doi

    @object.object_version = (@object.object_version.to_i+1).to_s
    updated = @object.update_attributes(update_params)

    #purge params from update action
    purge_params

    respond_to do |format|
      if updated
        MetadataHelpers.checksum_metadata(@object)
        @object.save

        warn_if_duplicates
        retrieve_linked_data

        actor.version_and_record_committer
        update_doi(@object, doi, 'metadata update') if doi && doi.changed?

        # Moabify the descMetadata & properties (checksum_md5 and doi)  datastream
        @object.reload # we must refresh the datastreams list 
        preservation = Preservation::Preservator.new(@object.id, @object.object_version)
        preservation.create_moab_dirs()
        preservation.moabify_datastream('descMetadata', @object.datastreams['descMetadata'])
        preservation.moabify_datastream('properties', @object.datastreams['properties'])

        flash[:notice] = t('dri.flash.notice.metadata_updated')
        format.html  { redirect_to :controller => 'catalog', :action => 'show', :id => @object.id }
        format.json  { render :json => @object }
      else
        flash[:alert] = t('dri.flash.alert.invalid_object', :error => @object.errors.full_messages.inspect)
        format.html  { render :action => 'edit' }
        format.json  { render :json => @object }
      end
    end

  end

  def citation
    enforce_permissions!("show_digital_object",params[:id])

    @object = retrieve_object!(params[:id])
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    params[:batch][:read_users_string] = params[:batch][:read_users_string].to_s.downcase
    params[:batch][:edit_users_string] = params[:batch][:edit_users_string].to_s.downcase

    if params[:batch][:governing_collection].present?
      params[:batch][:governing_collection] = DRI::Batch.find(params[:batch][:governing_collection])
      # governing_collection present and also whether this is a documentation object?
      if params[:batch][:documentation_for].present?
        params[:batch][:documentation_for] = DRI::Batch.find(params[:batch][:documentation_for])
      end
    end

    enforce_permissions!("create_digital_object",params[:batch][:governing_collection].id)

    if params[:batch][:documentation_for].present?
      create_from_form :documentation
    elsif params[:metadata_file].present?
      create_from_upload
    else
      create_from_form
    end

    MetadataHelpers.checksum_metadata(@object)
    
    supported_licences()

    @object.object_version = "1"

    if @object.valid? && @object.save
      warn_if_duplicates

      create_reader_group if @object.is_collection?
      retrieve_linked_data

      actor.version_and_record_committer

      @object.reload # we must refresh the datastreams list

      # Create MOAB dir
      preservation = Preservation::Preservator.new(@object.id, @object.object_version)
      preservation.create_moab_dirs()
      @object.datastreams.each do |key,value|
        preservation.moabify_datastream(key, value)
      end

      respond_to do |format|
        format.html { flash[:notice] = t('dri.flash.notice.digital_object_ingested')
        redirect_to :controller => "catalog", :action => "show", :id => @object.id
        }
        format.json {
          if @warnings
            response = { :pid => @object.id, :warning => @warnings }
          else
            response = { :pid => @object.id }
          end
          render :json => response, :location => catalog_url(@object.id), :status => :created }
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

  def destroy
    enforce_permissions!("edit", params[:id])

    @object = retrieve_object!(params[:id])
    
    if @object.status != "published"
      @object.delete 
      flash[:notice] = t('dri.flash.notice.object_deleted')  
    else
      raise Hydra::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, "")
    end

    respond_to do |format|
      format.html { redirect_to :controller => "catalog", :action => "index" }
    end
  end

  def index
    @list = []

    if params.has_key?("objects") && !params[:objects].blank?
      solr_query = ActiveFedora::SolrService.construct_query_for_ids(params[:objects].map{|o| o.values.first})
      results = Solr::Query.new(solr_query)
      
      while results.has_more?
        docs = results.pop

        docs.each do | doc |
          solr_doc = SolrDocument.new(doc)
          item = extract_metadata solr_doc
                  
          if solr_doc.published?
            item = extract_metadata solr_doc
            item.merge!(find_assets_and_surrogates solr_doc)

            @list << item
          end
        end

        raise Exceptions::NotFound if @list.empty?
      end

    else
      logger.error "No objects in params #{params.inspect}"
      raise Exceptions::BadRequest
    end

    respond_to do |format|
      format.json  { }
    end
  end


  def related
    enforce_permissions!("show_digital_object",params[:object])

    if params.has_key?("count") && params[:count].present? && numeric?(params[:count])
      count = params[:count]
    else
      count = 3
    end

    if params.has_key?("object") && !params[:object].blank?
      solr_query = ActiveFedora::SolrService.construct_query_for_pids([params[:object]])
      result = ActiveFedora::SolrService.instance.conn.get('select',
                        :params=>{:q=>solr_query, :qt => 'standard',
                        :mlt => 'true',
                        :'mlt.fl' => "#{Solrizer.solr_name('subject', :stored_searchable, type: :string)},#{Solrizer.solr_name('subject', :stored_searchable, type: :string)}",
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

    raise Exceptions::BadRequest if @object.is_collection?

    unless @object.status.eql?("published")
      @object.status = params[:status] if params[:status].present?
      @object.save
    end

    if params[:apply_all].present? && params[:apply_all].eql?("yes")
      begin
        Sufia.queue.push(ReviewJob.new(@object.governing_collection.id)) unless @object.governing_collection.nil?
      rescue Exception => e
        logger.error "Unable to submit status job: #{e.message}"
        flash[:alert] = t('dri.flash.alert.error_review_job', :error => e.message)
        @warnings = t('dri.flash.alert.error_review_job', :error => e.message)
      end
    end

    respond_to do |format|
      flash[:notice] = t('dri.flash.notice.metadata_updated')
      format.html  { redirect_to :controller => "catalog", :action => "show", :id => @object.id }
      format.json {
        unless @warnings.nil?
          response = { :warning => @warnings, :id => @object.id, :status => @object.status }
        else
          response = { :id => @object.id, :status => @object.status }
        end
        render :json => response, :status => :accepted }
    end
  end

  private

    def create_from_upload
      xml = MetadataHelpers.load_xml(params[:metadata_file])
      standard = MetadataHelpers.get_metadata_standard_from_xml xml

      @object = DRI::Batch.with_standard standard
      @object.depositor = current_user.to_s
      @object.update_attributes create_params

      MetadataHelpers.set_metadata_datastream(@object, xml)
    end

    # If no standard parameter then default to :qdc
    # allow to create :documentation and :marc objects (improve merging into marc-nccb branch)
    #
    def create_from_form standard=nil
      if standard
        @object = DRI::Batch.with_standard standard
      else
        @object = DRI::Batch.with_standard :qdc
      end
      @object.depositor = current_user.to_s
      @object.update_attributes create_params
    end

    def create_reader_group
      group = UserGroup::Group.new(:name => "#{@object.id}", :description => "Default Reader group for collection #{@object.id}")
      group.reader_group = true
      group.save
    end

    def extract_metadata doc
      item = {}

      # Get metadata
      item['pid'] = doc.id
      item['metadata'] = {}

      DEFAULT_METADATA_FIELDS.each do |field|

        if params['metadata'].blank? || params['metadata'].include?(field)
          value = doc[ActiveFedora::SolrQueryBuilder.solr_name(field, :stored_searchable)]

          case field
          when "institute"
            item['metadata'][field] = InstituteHelpers.get_institutes_from_solr_doc(doc)
          
          when "geocode_point"
            if value.present?
              geojson_points = []
              value.each { |point| geojson_points << dcterms_point_to_geojson(point) }

              item['metadata'][field] = geojson_points
            end
          
          when "geocode_box"
            if value.present?
              geojson_boxes = []
              value.each { |box| geojson_boxes << dcterms_box_to_geojson(box) }
    
              item['metadata'][field] = geojson_boxes
            end
          
          when field.include?("date") || field == "temporal_coverage"
            if value.present?
              dates = []
              value.each { |d| dates << dcterms_period_to_string(d) }

              item['metadata'][field] = dates
            end
          
          else
            item['metadata'][field] = value if value
          end

        end
      end

      item
    end

    def find_assets_and_surrogates doc
      item = {}
      item['files'] = []

      # Get files
      if can? :read, doc
        storage = Storage::S3Interface.new

        files_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{doc.id}\" AND NOT #{ActiveFedora::SolrQueryBuilder.solr_name('dri_properties__preservation_only', :stored_searchable)}:true"
        query = Solr::Query.new(files_query)

        while query.has_more?
          files = query.pop

          files.each do |mf|
            file_list = {}
            file_doc = SolrDocument.new(mf)

            if (doc.read_master? && can?(:read, doc)) || can?(:edit, doc)
              url = url_for(file_download_url(doc.id, file_doc.id))
              file_list['masterfile'] = url
            end

            timeout = 60 * 60 * 24 * 7 # 1 week, maximum allowed by AWS API
            surrogates = storage.get_surrogates doc, file_doc, timeout
            surrogates.each { |file,loc| file_list[file] = loc }

            item['files'].push(file_list)
          end
        end

      end

      item
    end

    def retrieve_linked_data
      if AuthoritiesConfig
        begin
          Sufia.queue.push(LinkedDataJob.new(@object.id)) if @object.geographical_coverage.present?
        rescue Exception => e
          Rails.logger.error "Unable to submit linked data job: #{e.message}"
        end
      end
    end

end

