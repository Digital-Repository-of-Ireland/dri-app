module ApplicationHelper
  require 'storage/s3_interface'

  # Returns the file that should be delivered to the user
  # based on their access rights and the policies and available
  # surrogates of the object
  def get_delivery_file doc, file_doc
    @asset = nil
    storage = Storage::S3Interface.new
    delivery_file = storage.deliverable_surrogate?(doc, file_doc)
    @asset = storage.get_link_for_surrogate(doc.id.sub('dri:',''), delivery_file) unless (delivery_file.blank?)
    storage.close
  end

  def get_files doc
    @files = ActiveFedora::Base.find(doc.id, {:cast => true}).generic_files
    ""
  end

  def get_surrogates doc, file_doc
    storage = Storage::S3Interface.new
    surrogates = storage.get_surrogates doc, file_doc
    storage.close

    surrogates
  end

  def surrogate_url( doc, file_doc, name )
    storage = Storage::S3Interface.new
    url = storage.surrogate_url(doc, file_doc, name)
    storage.close

    url
  end

  def governing_collection( object )
    object.governing_collection.pid unless object.governing_collection.nil?
  end

  def root_collection_solr( doc )
    if doc[:root_collection_id_tesim]
      id = doc[:root_collection_id_tesim][0]
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1")
    end
    collection[0]
  end

  def governing_collection_solr( doc )
    if doc['is_governed_by_ssim']
      id = doc['is_governed_by_ssim'][0].gsub(/^info:fedora\//, '')
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1")
    return collection[0]
    end
    return nil
  end

  def get_partial_name( object )
    object.class.to_s.downcase.gsub("-"," ").parameterize("_")
  end

  def search_image ( document, file_document, image_name = "crop16_9_width_200_thumbnail" )
    path = nil

    unless file_document['file_type_tesim'].blank?
      format = file_document['file_type_tesim'].first

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
    path = "no_image.png"

    unless file_document.nil?
      unless file_document['file_type_tesim'].blank?
        format = file_document['file_type_tesim'].first

        path = "dri/formats/#{format}.png"

        if Rails.application.assets.find_asset(path).nil?
          path = "no_image.png"
        end
      end
    end

    path
  end

  def cover_image ( document )
    path = nil

    if document[:cover_image_tesim] && document[:cover_image_tesim].first
        path = document[:cover_image_tesim].first
    elsif !document[:root_collection_tesim].blank?
      collection = root_collection_solr(document)
      if collection['cover_image_tesim'] && collection['cover_image_tesim'].first
        path = collection['cover_image_tesim'].first
      end
    end

    path
  end

  def icon_path ( document )
    format = format?(document)

    format.eql?("unknown") ? "no_image.png" : "dri/formats/#{format}_icon.png"
  end

  def reader_group_name( document )
    id = document[:root_collection_id_tesim][0]
    name = id.sub(':','_')
    return name
  end

  def count_items_in_collection collection_id
    solr_query = collection_children_query( collection_id )

    unless signed_in? && can?(:edit, collection_id)
      solr_query = "status_ssim:published AND " + solr_query
    end

    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def collection_children_query ( collection_id )
    "(ancestor_id_tesim:\"" + collection_id +
    "\" OR is_member_of_collection_ssim:\"info:fedora/" + collection_id + "\" )"
  end

  def count_items_in_collection_by_type_and_status( collection_id, type, status )
    solr_query = "status_ssim:" + status + " AND (ancestor_id_tesim:\"" + collection_id +
    "\" OR is_member_of_collection_ssim:\"info:fedora/" + collection_id + "\" ) AND " +
    "file_type_display_tesim:"+ type
    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def count_collections_institute( institute_tesim, status )
    solr_query = "status_ssim:" + status + " AND institute_tesim:" + institute_tesim + " AND " +
    "type_tesim:Collection"
    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def count_items_in_collection_by_type(collection_id, type)
    solr_query = "(ancestor_id_tesim:\"" + collection_id +
        "\" OR is_member_of_collection_ssim:\"info:fedora/" + collection_id + "\" ) AND " +
        "file_type_display_tesim:"+ type
    unless signed_in? && can?(:edit, collection_id)
      solr_query = "status_ssim:published AND " + solr_query
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
      @coll_counts = count_collections_institute(institute, "published")
  end

  def get_institutes( document )
    @collection_institutes = InstituteHelpers.get_institutes_from_solr_doc(document)
    @depositing_institute = InstituteHelpers.get_depositing_institute_from_solr_doc(document)
  end

  def get_cover_image( document )
    files_query = "is_part_of_ssim:\"info:fedora/#{document[:id]}\""
    files = ActiveFedora::SolrService.query(files_query)
    file_doc = SolrDocument.new(files.first) unless files.empty?

    if can?(:read, document)
      @cover_image = search_image( document, file_doc ) unless file_doc.nil?
    end

    @cover_image = cover_image ( document ) if @cover_image.nil?

    @cover_image = default_image ( file_doc ) if @cover_image.nil?
  end

  def get_licence( document )
    if !document[:licence_tesim].blank?
      @licence = Licence.where(:name => document[:licence_tesim]).first
    elsif !document[:root_collection_tesim].blank?
      collection = root_collection_solr(document)
      if !collection['licence_tesim'].blank?
        @licence = Licence.where(:name => collection['licence_tesim']).first
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

end

