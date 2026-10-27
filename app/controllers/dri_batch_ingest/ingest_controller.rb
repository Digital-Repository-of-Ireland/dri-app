# frozen_string_literal: true
class DRIBatchIngest::IngestController < ApplicationController
  include DRIBatchIngest::BatchLookup
  include DRI::Renderers::Json
  include DRIBatchIngest::BatchSummaries

  before_action :authenticate_user!
  before_action :read_only, except: [:index, :show]
  before_action :set_batch, only: %i[show update]

  def base_dir
    @base_dir ||= DRIBatchIngest::UserStorage.home_for(current_user.email)
  end

  def index; end

  def new
    @collections = user_collections
    @ingests = DRIBatchIngest::UserIngest.where(user_id: current_user.id).order(created_at: :desc).page(params[:page]).per(5)
    @batches = user_batches

    begin
      Dir.chdir(base_dir) { @user_dirs = directory_hash('.')[:children] }
    rescue Errno::ENOENT
      @user_dirs = nil
    end
  end

  def show
    @media_objects = if params[:status]
                       @batch.media_objects.status(params[:status]).page(params[:page]).per(25)
                     else
                       @batch.media_objects.page(params[:page]).per(25)
                     end
  end

  def create
    collection = params[:collection_id]

    begin
      validate_ingest_paths!
    rescue ArgumentError
      return head :bad_request
    end
    
    ingest = DRIBatchIngest::UserIngest.create(user_id: current_user.id)

    metadata_path = params[:metadata_path]
    asset_path = params[:asset_path]
    preservation_path = params[:preservation_path]

    Resque.enqueue(DRIBatchIngest::CreateManifest, ingest.id, base_dir, current_user.email, collection, metadata_path, asset_path.presence, preservation_path.presence)
   
    redirect_to ingests_url
  end

  def update
    media_object_ids = @batch.media_objects.status('FAILED').pluck(:id)
    Resque.enqueue(DRIBatchIngest::ProcessBatch, @batch.id, media_object_ids)

    redirect_to ingests_url
  end

  private
  
  def set_batch
    @batch = find_user_batch(params[:id])
  end

  def validate_ingest_paths!
    raise ArgumentError, 'metadata path required' if params[:metadata_path].blank?

    %i[metadata_path asset_path preservation_path].each do |key|
      next if params[key].blank?
      DRIBatchIngest::UserStorage.resolve(current_user.email, params[key])
    end
  end

  def user_collections
    # User should see any collections that they have manage or edit permissions for
    query = "({!join from=id to=ancestor_id_ssim}manager_access_person_ssim:\"#{current_user.email}\" OR manager_access_person_ssim:\"#{current_user.email}\")"
    query += " OR ({!join from=id to=ancestor_id_ssim}edit_access_person_ssim:\"#{current_user.email}\" OR edit_access_person_ssim:\"#{current_user.email}\")"

    fq = ["+is_collection_ssi:true"]
    fq << "+isGovernedBy_ssim:#{params[:governing]}" if params[:governing].present?
    fq << "+has_model_ssim:\"DRI::QualifiedDublinCore\""

    solr_query = Solr::Query.new(query, 100, { fq: fq, "defType" => "lucene" })
    nested_hash(build_collection_entries(solr_query))
  end

  def build_collection_entries(solr_query)
    entries = []
    solr_query.each do |document|
      id = document.id
      title = document['title_tesim'].first
      parents = document['ancestor_id_ssim']

      entries << { id: id, type: 'folder', text: title, parent_id: parents.nil? ? nil : parents.first }
    end

    entries
  end

  def nested_hash(entries)
    nested_hash = Hash[entries.map { |e| [e[:id], e.merge(children: [])] }]
    nested_hash.each do |_id, item|
      parent = nested_hash[item[:parent_id]]
      parent[:children] << item if parent
    end
    nested_hash.select { |_id, item| item[:parent_id].nil? }.values
  end

  def directory_hash(path, name = nil, exclude = [])
    exclude.concat(['..', '.', '.git', '__MACOSX', '.DS_Store'])
    key = (name || path)
    data = { text: key, type: 'folder', data: { path: path } }
    data[:children] = []
    Dir.foreach(path) do |entry|
      next if exclude.include?(entry)
      full_path = path == '.' ? entry : File.join(path, entry)
      data[:children] << directory_hash(full_path, entry) if File.directory?(full_path)
    end

    data
  end
end
