# Controller for Digital Objects
#
require 'solr/query'

include Utils

class ObjectsController < BaseObjectsController

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
    if @object.creator[0] == nil
      @object.creator = [""]
    end
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
    params[:batch][:read_users_string] = params[:batch][:read_users_string].to_s.downcase
    params[:batch][:edit_users_string] = params[:batch][:edit_users_string].to_s.downcase
    params[:batch][:manager_users_string] = params[:batch][:manager_users_string].to_s.downcase

    update_object_permission_check(params[:batch][:manager_groups_string], params[:batch][:manager_users_string], params[:id])
    supported_licences()

    @object = retrieve_object!(params[:id])

    if params[:batch][:governing_collection_id].present?
      collection = DRI::Batch.find(params[:batch][:governing_collection_id])
      @object.governing_collection = collection
    end

    update_doi = doi_update_required?

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
        actor.mint_doi("metadata update") if update_doi

        flash[:notice] = t('dri.flash.notice.metadata_updated')
        format.html  { redirect_to :controller => "catalog", :action => "show", :id => @object.id }
        format.json  { render :json => @object }
      else
        flash[:alert] = t('dri.flash.alert.invalid_object', :error => @object.errors.full_messages.inspect)
        format.html  { render :action => "edit" }
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

    if @object.valid? && @object.save
      warn_if_duplicates

      create_reader_group if @object.is_collection?
      retrieve_linked_data

      actor.version_and_record_committer

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

  def index
    @list = []

    if params.has_key?("objects") && !params[:objects].blank?
      solr_query = ActiveFedora::SolrService.construct_query_for_pids(params[:objects].map{|o| o.values.first})
      result_docs = Solr::Query.new(solr_query)

      storage = Storage::S3Interface.new

      while result_docs.has_more?
        doc = result_docs.pop

        doc.each do | r |
          item = {}
          doc = SolrDocument.new(r)

          if doc.status.first.eql?('published')
            # Get metadata
            item['pid'] = doc.id
            item['files'] = []
            item['metadata'] = {}

            ['title','subject','creation_date','published_date','type','rights','language','description','creator',
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
                elsif field.include?("date") || field.eql?("temporal_coverage")
                  if !value.nil? && !value.blank?
                    dates = []
                    value.each do |d|
                      dates << dcterms_period_to_string(d)
                    end
                    item['metadata'][field] = dates
                  end
                else
                  item['metadata'][field] = value unless value.nil?
                end
              end
            end

            # Get files
            if can? :read, doc
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
                  surrogates.each do |file,loc|
                    file_list[file] = loc
                  end

                  item['files'].push(file_list)
                end
              end

            end

            @list << item
          end
        end

        raise Exceptions::NotFound if @list.empty?
      end

    else
      logger.error "No objects in params #{params.inspect}"
      raise raise Exceptions::BadRequest
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

    def retrieve_linked_data
      if AuthoritiesConfig
        begin
          Sufia.queue.push(LinkedDataJob.new(@object.id)) unless @object.geographical_coverage.blank?
        rescue Exception => e
          Rails.logger.error "Unable to submit linked data job: #{e.message}"
        end
      end
    end
end

