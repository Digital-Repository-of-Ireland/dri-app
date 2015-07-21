module ApplicationHelper
  require 'storage/s3_interface'
  require 'institute_helpers'
  require 'uri'

  def get_files doc
    @files = ActiveFedora::SolrService.query("active_fedora_model_ssi:\"DRI::GenericFile\" AND #{ActiveFedora::SolrQueryBuilder.solr_name("isPartOf", :symbol)}:#{doc.id}", rows: 200)
    @files = @files.map {|f| SolrDocument.new(f)}.sort_by{ |f| f[ActiveFedora::SolrQueryBuilder.solr_name("label")] }
    @displayfiles = []
    @files.each do |file|
      @displayfiles << file unless file.preservation_only?
    end
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

  def get_partial_name( object )
    object.class.to_s.downcase.gsub("-"," ").parameterize("_")
  end

  def get_metadata_name( object )
    object.descMetadata.class.to_s.downcase.split('::').last
  end

  def search_image ( document, file_document, image_name = "crop16_9_width_200_thumbnail" )
    path = nil

    unless file_document[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].blank?
      format = file_document[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].first

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
      unless file_document[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].blank?
        format = file_document[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].first

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

    if document[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string).to_sym] && document[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string).to_sym].first
        path = document[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string).to_sym].first
    elsif document[ActiveFedora::SolrQueryBuilder.solr_name('root_collection', :stored_searchable, type: :string).to_sym].present?
      collection = document.root_collection
      if collection[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string)] && collection[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string)].first
        path = collection[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string)].first
      end
    end

    path
  end

  def icon_path ( document )
    format = document[ActiveFedora::SolrQueryBuilder.solr_name('file_type_display', :stored_searchable, type: :string).to_sym].first.to_s.downcase

    if (format != 'image' && format != 'audio' && format != 'text' && format != 'video' && format != 'mixed_types')
      "no_image.png"
    else
      "dri/formats/#{format}_icon.png"
    end
  end

  def count_items_in_collection collection_id
    solr_query = collection_children_query( collection_id )

    unless signed_in? && can?(:edit, collection_id)
      solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :symbol)}:published AND " + solr_query
    end

    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def count_immediate_children_in_collection collection_id
    solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('collection_id', :stored_searchable, type: :string)}:\"#{collection_id}\""
    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def collection_children_query ( collection_id )
    "(#{ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable, type: :string)}:\"" + collection_id +
    "\" AND is_collection_sim:false" +
    " OR #{ActiveFedora::SolrQueryBuilder.solr_name('is_member_of_collection', :stored_searchable, type: :symbol)}:\"info:fedora/" + collection_id + "\" )"
  end

  def count_items_in_collection_by_type_and_status( collection_id, type, status )
    solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :symbol)}:" + status + " AND (#{ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable, type: :string)}:\"" + collection_id +
    "\" OR #{ActiveFedora::SolrQueryBuilder.solr_name('is_member_of_collection', :stored_searchable, type: :symbol)}:\"info:fedora/" + collection_id + "\" ) AND " +
    "#{ActiveFedora::SolrQueryBuilder.solr_name('file_type_display', :stored_searchable, type: :string)}:"+ type
    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def get_query_collections_by_institute( institute )
    solr_query = ""
    if !signed_in? || (!current_user.is_admin? && !current_user.is_cm?)
      solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :symbol)}:published AND "
    end
    solr_query = solr_query + "#{ActiveFedora::SolrQueryBuilder.solr_name('institute', :stored_searchable, type: :string)}:\"" + institute + "\" AND " +
        "#{ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable, type: :string)}:Collection"
    return solr_query
  end

  def count_collections_institute( institute )
    solr_query = get_query_collections_by_institute(institute)
    count = ActiveFedora::SolrService.count(solr_query, :defType => "edismax", :fq => "-#{ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]")
    return count
  end

  def get_collections_institute( institute )
    solr_query = get_query_collections_by_institute(institute)
    response = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :fq => "-#{ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]")
    return response
  end

  def count_items_in_collection_by_type(collection_id, type)
    solr_query = "(#{ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable, type: :string)}:\"" + collection_id +
        "\" OR #{ActiveFedora::SolrQueryBuilder.solr_name('is_member_of_collection', :stored_searchable, type: :symbol)}:\"info:fedora/" + collection_id + "\" ) AND " +
        "#{ActiveFedora::SolrQueryBuilder.solr_name('file_type_display', :stored_searchable, type: :string)}:"+ type
    unless signed_in? && can?(:edit, collection_id)
      solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :symbol)}:published AND " + solr_query
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

  def get_institutes()
      return Institute.all
  end

  # method to find the Institutes associated with and available to add to or remove from the current collection (document) 
  def get_available_institutes( document )
    # the full list of Institutes
    @institutes = InstituteHelpers.get_all_institutes()
    # the Institutes currently associated with this collection if any
    @collection_institutes = InstituteHelpers.get_institutes_from_solr_doc( document )
    # the Depositing Institute if any
    @depositing_institute = InstituteHelpers.get_depositing_institute_from_solr_doc( document )
    institutes_array = []
    collection_institutes_array = []
    depositing_institute_array = []
    depositing_institute_array.push( @depositing_institute.name ) unless @depositing_institute.blank?
    @institutes.each do |inst|
      institutes_array.push( inst.name )
    end
    if @collection_institutes.any?
      @collection_institutes.each do |inst|
        collection_institutes_array.push( inst.name )
      end
    end
    # exclude the associated and depositing Institutes from the list of Institutes available
    @available_institutes = institutes_array - collection_institutes_array - depositing_institute_array
    # exclude the depositing Institute from the list of Institutes which can be removed
    @removal_institutes = collection_institutes_array - depositing_institute_array
  end
  
  # method to find the depositing Institute (if any) associated with the current collection (document) 
  def get_depositing_institute ( document )
    @depositing_institute = InstituteHelpers.get_depositing_institute_from_solr_doc( document )
  end


  # Called from grid view
  def get_cover_image( document )
    files_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{document[:id]}\" AND NOT #{ActiveFedora::SolrQueryBuilder.solr_name('preservation_only', :stored_searchable)}:true"
    files = ActiveFedora::SolrService.query(files_query)
    file_doc = nil
    files.each do |file|
      file_doc = SolrDocument.new(file) unless files.empty?
      if can?(:read, document[:id])
        @cover_image = search_image( document, file_doc ) unless file_doc.nil?
        if !@cover_image.nil? then
          break
        end
      end
    end

    @cover_image = default_image ( file_doc ) if @cover_image.nil?
  end

  def get_licence( document )
    if document[ActiveFedora::SolrQueryBuilder.solr_name('licence', :stored_searchable, type: :string).to_sym].present?
      @licence = Licence.where(:name => document[ActiveFedora::SolrQueryBuilder.solr_name('licence', :stored_searchable, type: :string).to_sym]).first
      if (@licence == nil)
        @licence = document[ActiveFedora::SolrQueryBuilder.solr_name('licence', :stored_searchable, type: :string).to_sym]
      end
    elsif document[ActiveFedora::SolrQueryBuilder.solr_name('root_collection', :stored_searchable, type: :string).to_sym].present?
      collection = document.root_collection
      if collection[ActiveFedora::SolrQueryBuilder.solr_name('licence', :stored_searchable, type: :string)].present?
        @licence = Licence.where(:name => collection[ActiveFedora::SolrQueryBuilder.solr_name('licence', :stored_searchable, type: :string)]).first
      end
    end
  end

  def reader_group( collection_id )
    UserGroup::Group.find_by_name(collection_id)
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

  def is_root?
    return request.env['PATH_INFO'] == '/' && request.query_string.blank?
  end

  def has_search_parameters?
    params[:q].present? or params[:f].present? or params[:search_field].present?
  end

  def link_to_loc(field)
    return link_to('?', "http://www.loc.gov/marc/bibliographic/bd" + field + ".html" )
  end

  # Get the ID of the documentation object; nil if not available
  #
  def get_documentation_object(document)
    # Try first to see if the parent collection has documentation objects
    gov_col_doc_id = document.collection_id

    if gov_col_doc_id.nil? # root_collection
      # Look then for documentation objects in the Root collection
      root_doc = document.root_collection
      if (root_doc.nil?)
        return nil
      else
        root_col = DRI::Batch.find(root_doc["id"])
        if !root_col.documentation_object_ids.first.nil?
          return root_col.documentation_object_ids.first
        else
          return nil
        end
      end
    else
      gov_col = DRI::Batch.find(gov_col_doc_id)
      if !gov_col.documentation_object_ids.first.nil?
        return gov_col.documentation_object_ids.first
      else
        # no doc for the immediate parent, then try with the root_collection
        root_doc = document.root_collection
        if (root_doc.nil?)
          return nil
        else
          root_col = DRI::Batch.find(root_doc["id"])
          if !root_col.documentation_object_ids.first.nil?
            return root_col.documentation_object_ids.first
          else
            return nil
          end
        end
      end
    end
  end

  def get_reader_group(doc)
    readgroups = doc["#{Solrizer.solr_name('read_access_group', :stored_searchable, type: :symbol)}"]
    group = reader_group(doc['id'])
    if group
      if readgroups.present? && readgroups.include?(group.name)
        return @reader_group = group
      end
    end

    return nil
  end

end

