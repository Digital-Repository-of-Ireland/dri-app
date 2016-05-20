module ApplicationHelper
  require 'storage/s3_interface'
  require 'institute_helpers'
  require 'uri'

  def surrogate_url( doc, file_doc, name )
    storage = StorageService.new
    storage.surrogate_url(doc, "#{file_doc}_#{name}")
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

  def cover_image ( doc )
    path = nil
   
    document = doc.is_a?(SolrDocument) ? doc : SolrDocument.new(doc)
 
    cover_key = ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string).to_sym

    if document[cover_key].present? && document[cover_key].first
        path = cover_image_path(document)
    elsif document[ActiveFedora::SolrQueryBuilder.solr_name('root_collection', :stored_searchable, type: :string).to_sym].present?
      collection = document.root_collection

      if collection[cover_key].present? && collection[cover_key].first
        path = cover_image_path(collection)
      end
    end
    
    path
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
        
  def count_items_in_collection_by_type(collection_id, type)
    solr_query = "(#{ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable, type: :string)}:\"" + collection_id +
        "\" OR #{ActiveFedora::SolrQueryBuilder.solr_name('is_member_of_collection', :stored_searchable, type: :symbol)}:\"info:fedora/" + collection_id + "\" ) AND " +
        "#{ActiveFedora::SolrQueryBuilder.solr_name('file_type_display', :stored_searchable, type: :string)}:"+ type
    unless signed_in? && can?(:edit, collection_id)
      solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :symbol)}:published AND " + solr_query
    end
    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  # method to find the depositing Institute (if any) associated with the current collection (document) 
  def get_depositing_institute ( document )
    @depositing_institute = InstituteHelpers.get_depositing_institute_from_solr_doc( document )
  end

  # Called from grid view
  def image_for_search( document )
    files_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{document[:id]}\" AND NOT #{ActiveFedora::SolrQueryBuilder.solr_name('preservation_only', :stored_searchable)}:true"
    files = ActiveFedora::SolrService.query(files_query)
    
    file_doc = nil
    image = nil

    files.each do |file|
      file_doc = SolrDocument.new(file) unless files.empty?
      if can?(:read, document[:id])
        image = search_image( document, file_doc ) unless file_doc.nil?
        break if image
      end
    end

    @search_image = image || default_image( file_doc )
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

  #URI Checker
  def uri?(string)
    uri = URI.parse(string)
    %w( http https ).include?(uri.scheme)
  rescue URI::BadURIError
    false
  rescue URI::InvalidURIError
    false
  end

end

