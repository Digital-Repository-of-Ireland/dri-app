# Controller for API
#
require 'solr/query'
require 'faraday'
require 'faraday_middleware'
require 'json'

class ApiController < CatalogController
  include Blacklight::AccessControls::Catalog

  before_action :authenticate_user_from_token!, except:  [:enrichments]
  before_action :authenticate_user!, except:  [:enrichments]
  before_action :add_cors_to_json, only: :assets

  def objects
    @list = []
    if params[:objects].present?
      object_ids = params[:objects].map { |o| o.values.first }
    else
      err_msg = 'No objects in params'
      logger.error "#{err_msg} #{params.inspect}"
      raise DRI::Exceptions::BadRequest
    end

    solr_query = Solr::Query.construct_query_for_ids(object_ids)
    results = Solr::Query.new(solr_query)

    results.each do |solr_doc|
      next unless solr_doc.published? || (current_user.is_admin? || can?(:edit, solr_doc))

      item = Rails.cache.fetch("get_objects-#{solr_doc.id}-#{solr_doc['timestamp']}") do
               solr_doc.extract_metadata(params[:metadata])
             end

      item['metadata']['licence'] = DRI::Formatters::Json.licence(solr_doc)
      item['metadata']['doi'] = DRI::Formatters::Json.dois(solr_doc)
      item['metadata']['related_objects'] = solr_doc.object_relationships_as_json

      timeout = 60 * 60 * 24 * 7
      item['files'] = assets_and_surrogates(solr_doc)

      @list << item
    end

    raise DRI::Exceptions::NotFound if @list.empty?

    respond_to do |format|
      format.json { render(json: @list) }
    end
  end

  # API call: takes one or more object ids and returns a list of asset urls
  def assets
    @list = []

    raise DRI::Exceptions::BadRequest unless params[:objects].present?

    solr_query = Solr::Query.construct_query_for_ids(
      params[:objects].map { |o| o.values.first }
    )
    result_docs = Solr::Query.new(solr_query)
    result_docs.each do |doc|
      item = {}
      item['pid'] = doc.id
      item['files'] = assets_and_surrogates(doc)

      @list << item unless item.empty?
    end

    raise DRI::Exceptions::NotFound if @list.empty?

    respond_to do |format|
      format.json
    end
  end

  def related
    enforce_permissions!('show_digital_object', params[:object])

    count = if params[:count].present? && numeric?(params[:count])
              params[:count]
            else
              3
            end

    if params[:object].present?
      solr_query = Solr::Query.construct_query_for_ids([params[:object]])
      result = Solr::Query.repository.connection.get(
        'select',
        params: {
          q: solr_query, qt: 'standard',
          fq: "is_collection_ssi:false
               AND status_ssi:published",
          mlt: 'true',
          :'mlt.fl' => "#{Solr::SchemaFields.searchable_string('subject')},
                        #{Solr::SchemaFields.searchable_string('subject')}",
          :'mlt.count' => count,
          fl: 'id,score',
          :'mlt.match.include' => 'false'
        }
      )
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

  def enrichments
    if params[:recordId].present?
      (europeana_id, dri_id) = params[:recordId].tr('/', '').split("_")
      document = SolrDocument.find(dri_id)
      
      # may need object
      agg_id = Aggregation.where(collection_id: document['root_collection_id_ssi']).first.aggregation_id
      if not (agg_id == europeana_id)
        err_msg = "Aggregation information not found"
        logger.error "#{err_msg} #{agg_id} #{params.inspect}"
        raise DRI::Exceptions::NotFound
      end

      # parse story ID from the request body
      #json_params = JSON.parse(request.raw_post) 
      json_params = JSON.parse(request.raw_post)
      # get story


      #story = TpStory.find_or_create_by(dri_id: "mc87pq24j")
      # parse out the Transcribathon ID
      # create TpStory object 
      if document.present?
        # sdf
      else
        raise DRI::Exceptions::NotFound
      end
    else
      err_msg = 'No record id in params'
      logger.error "#{err_msg} #{params.inspect}"
      raise DRI::Exceptions::BadRequest
    end

    respond_to do |format|
      format.json
    end
  end

  private

  def add_cors_to_json
    if request.format == "application/json"
      response.headers["Access-Control-Allow-Origin"] = "*"
    end
  end

  def assets_and_surrogates(doc, timeout=nil)
    asset_list = []
    return asset_list unless can?(:read, doc)

    with_preservation = params[:preservation].present? && can?(:edit, doc)
    files = doc.assets(with_preservation: with_preservation)

    files.each do |file_doc|
      file_list = {}

      if doc.read_master? || can?(:edit, doc)
        url = url_for(file_download_url(doc.id, file_doc.id))
        file_list['masterfile'] = url
        file_list['preservation'] = true if file_doc.preservation_only?
      end

      surrogates = doc.surrogates(file_doc.id, timeout)
      surrogates.each { |file, loc| file_list[file] = loc }

      asset_list.push(file_list)
    end

    asset_list
  end

  def numeric?(number)
    Integer(number) rescue false
  end
end
