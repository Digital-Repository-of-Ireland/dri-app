module ApplicationHelper
  require 'storage/s3_interface'

  def get_files doc
    @files = ActiveFedora::Base.find(doc.id, {:cast => true}).generic_files
    ""
  end

  def get_surrogates doc, file_doc
    storage = Storage::S3Interface.new
    surrogates = storage.get_surrogates doc, file_doc

    surrogates
  end

  def get_surrogate_info object_id, file_id
    storage = Storage::S3Interface.new
    surrogates = storage.get_surrogate_info object_id, file_id

    surrogates
  end

  def surrogate_url( doc, file_doc, name )
    storage = Storage::S3Interface.new
    url = storage.surrogate_url(doc, file_doc, name)

    url
  end

  def get_asset_version_list( file_id, datastream )
    files = LocalFile.where("fedora_id LIKE :f AND ds_id LIKE :d", { :f => file_id, :d => datastream }).to_a
    return files
  end

  def governing_collection( object )
    object.governing_collection.pid unless object.governing_collection.nil?
  end

  def root_collection_solr( doc )
    if doc[Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string).to_sym]
      id = doc[Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string).to_sym][0]
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1")
    end
    collection[0]
  end

  def governing_collection_solr( doc )
    if doc[Solrizer.solr_name('is_governed_by', :stored_searchable, type: :symbol)]
      id = doc[Solrizer.solr_name('is_governed_by', :stored_searchable, type: :symbol)][0].gsub(/^info:fedora\//, '')
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1")
    return collection[0]
    end
    return nil
  end

  def get_partial_name( object )
    object.class.to_s.downcase.gsub("-"," ").parameterize("_")
  end

  def get_metadata_name( object )
    object.descMetadata.class.to_s.downcase.split('::').last
  end

  def search_image ( document, file_document, image_name = "crop16_9_width_200_thumbnail" )
    path = nil

    unless file_document[Solrizer.solr_name('file_type', :stored_searchable, type: :string)].blank?
      format = file_document[Solrizer.solr_name('file_type', :stored_searchable, type: :string)].first

      case format
      when "image"
        path = surrogate_url(document[:id], file_document.id, image_name)
      when "text"
        path = surrogate_url(document[:id], file_document.id, "thumbnail_medium")
      end
    end

    path
  end

  def default_image ( file_document )
    path = asset_url "no_image.png"

    unless file_document.nil?
      unless file_document[Solrizer.solr_name('file_type', :stored_searchable, type: :string)].blank?
        format = file_document[Solrizer.solr_name('file_type', :stored_searchable, type: :string)].first

        path = asset_url "dri/formats/#{format}.png"

        if Rails.application.assets.find_asset(path).nil?
          path = asset_url "no_image.png"
        end
      end
    end

    path
  end

  def cover_image ( document )
    path = nil

    if document[Solrizer.solr_name('cover_image', :stored_searchable, type: :string).to_sym] && document[Solrizer.solr_name('cover_image', :stored_searchable, type: :string).to_sym].first
        path = document[Solrizer.solr_name('cover_image', :stored_searchable, type: :string).to_sym].first
    elsif !document[Solrizer.solr_name('root_collection', :stored_searchable, type: :string).to_sym].blank?
      collection = root_collection_solr(document)
      if collection[Solrizer.solr_name('cover_image', :stored_searchable, type: :string)] && collection[Solrizer.solr_name('cover_image', :stored_searchable, type: :string)].first
        path = collection[Solrizer.solr_name('cover_image', :stored_searchable, type: :string)].first
      end
    end

    path
  end

  def icon_path ( document )
    format = document[Solrizer.solr_name('file_type_display', :stored_searchable, type: :string).to_sym].first.to_s.downcase

    if (format != 'image' && format != 'audio' && format != 'text' && format != 'video' && format != 'mixed_types')
      "no_image.png"
    else
      "dri/formats/#{format}_icon.png"
    end
  end

  def reader_group_name( document )
    id = document[Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string).to_sym][0]
    name = id.sub(':','_')
    return name
  end

  def count_items_in_collection collection_id
    solr_query = collection_children_query( collection_id )

    unless signed_in? && can?(:edit, collection_id)
      solr_query = "#{Solrizer.solr_name('status', :stored_searchable, type: :symbol)}:published AND " + solr_query
    end

    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def collection_children_query ( collection_id )
    "(#{Solrizer.solr_name('ancestor_id', :facetable, type: :string)}:\"" + collection_id +
    "\" AND is_collection_sim:false" +
    " OR #{Solrizer.solr_name('is_member_of_collection', :stored_searchable, type: :symbol)}:\"info:fedora/" + collection_id + "\" )"
  end

  def count_items_in_collection_by_type_and_status( collection_id, type, status )
    solr_query = "#{Solrizer.solr_name('status', :stored_searchable, type: :symbol)}:" + status + " AND (#{Solrizer.solr_name('ancestor_id', :facetable, type: :string)}:\"" + collection_id +
    "\" OR #{Solrizer.solr_name('is_member_of_collection', :stored_searchable, type: :symbol)}:\"info:fedora/" + collection_id + "\" ) AND " +
    "#{Solrizer.solr_name('file_type_display', :stored_searchable, type: :string)}:"+ type
    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def get_query_collections_by_institute( institute )
    solr_query = ""
    if !signed_in? || (!current_user.is_admin? && !current_user.is_cm?)
      solr_query = "#{Solrizer.solr_name('status', :stored_searchable, type: :symbol)}:published AND "
    end
    solr_query = solr_query + "#{Solrizer.solr_name('institute', :stored_searchable, type: :string)}:" + institute + " AND " +
        "#{Solrizer.solr_name('type', :stored_searchable, type: :string)}:Collection"
    return solr_query
  end

  def count_collections_institute( institute )
    solr_query = get_query_collections_by_institute(institute)
    count = ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
    return count
  end

  def get_collections_institute( institute )
    solr_query = get_query_collections_by_institute(institute)
    response = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")
    return response
  end

  def count_items_in_collection_by_type(collection_id, type)
    solr_query = "(#{Solrizer.solr_name('ancestor_id', :facetable, type: :string)}:\"" + collection_id +
        "\" OR #{Solrizer.solr_name('is_member_of_collection', :stored_searchable, type: :symbol)}:\"info:fedora/" + collection_id + "\" ) AND " +
        "#{Solrizer.solr_name('file_type_display', :stored_searchable, type: :string)}:"+ type
    unless signed_in? && can?(:edit, collection_id)
      solr_query = "#{Solrizer.solr_name('status', :stored_searchable, type: :symbol)}:published AND " + solr_query
    end
    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def get_object_type_counts( document )
    id = document.key?(:root_collection) ? document[:root_collection][0] : document.id

    @type_counts = {}
    Settings.data.types.each do |type|
      @type_counts[type] = { :published => count_items_in_collection_by_type_and_status( id, type, "published" ) }

      if signed_in? && (can? :edit, id)
        @type_counts[type][:draft] = count_items_in_collection_by_type_and_status( id, type, "draft" )
      end

    end
  end

  def get_institute_collection_counts( institute )
      @coll_counts = count_collections_institute(institute)
  end

  def get_institutes( document )
    @collection_institutes = InstituteHelpers.get_institutes_from_solr_doc(document)
    @depositing_institute = InstituteHelpers.get_depositing_institute_from_solr_doc(document)
  end

  def get_cover_image( document )
    files_query = "#{Solrizer.solr_name('is_part_of', :stored_searchable, type: :symbol)}:\"info:fedora/#{document[:id]}\""
    files = ActiveFedora::SolrService.query(files_query)
    file_doc = SolrDocument.new(files.first) unless files.empty?

    if can?(:read, document[:id])
      @cover_image = search_image( document, file_doc ) unless file_doc.nil?
    end

    @cover_image = cover_image ( document ) if @cover_image.nil?

    @cover_image = default_image ( file_doc ) if @cover_image.nil?
  end

  def get_licence( document )
    if !document[Solrizer.solr_name('licence', :stored_searchable, type: :string).to_sym].blank?
      @licence = Licence.where(:name => document[Solrizer.solr_name('licence', :stored_searchable, type: :string).to_sym]).first
      if (@licence == nil)
        @licence = document[Solrizer.solr_name('licence', :stored_searchable, type: :string).to_sym]
      end
    elsif !document[Solrizer.solr_name('root_collection', :stored_searchable, type: :string).to_sym].blank?
      collection = root_collection_solr(document)
      if !collection[Solrizer.solr_name('licence', :stored_searchable, type: :string)].blank?
        @licence = Licence.where(:name => collection[Solrizer.solr_name('licence', :stored_searchable, type: :string)]).first
      end
    end
  end

  def reader_group( collection )
    UserGroup::Group.find_by_name(collection['id'].sub(':', '_'))
  end

  def pending_memberships ( collection )
    pending = {}
    pending_memberships = reader_group( collection ).pending_memberships
    pending_memberships.each do |membership|
      user = UserGroup::User.find_by_id(membership.user_id)
      identifier = user.full_name+'('+user.email+')' unless user.nil?

      pending[identifier] = membership
    end

    pending
  end

  def has_browse_params?
    return has_search_parameters? || !params[:mode].blank? || !params[:search_field].blank? || !params[:view].blank?
  end

  def has_search_parameters?
    !params[:q].blank? or !params[:f].blank? or !params[:search_field].blank?
  end

  def custom_label_for_marc_field(sf)
    case sf
      when '245$a'
        'Title'
      when '100$a'
        'Creator'
      when '260$c'
        'Creation Date'
      when '500$a'
        'Description'
      when '506$a'
        'Rights'
    end
  end

  def link_to_loc(field)
    return link_to('?', "http://www.loc.gov/marc/bibliographic/bd" + field + ".html" )
  end

end

