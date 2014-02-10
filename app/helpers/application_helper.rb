module ApplicationHelper
  require 'storage/s3_interface'

  # Returns the file that should be delivered to the user
  # based on their access rights and the policies and available
  # surrogates of the object
  def get_delivery_file doc
    @asset = nil
    storage = Storage::S3Interface.new
    delivery_file = storage.deliverable_surrogate?(doc)
    @asset = storage.get_link_for_surrogate(doc.id.sub('dri:',''), delivery_file) unless (delivery_file.blank?)
    storage.close
  end

  def get_files doc
    @files = ActiveFedora::Base.find(doc.id, {:cast => true}).generic_files
    ""
  end

  def get_surrogates doc
    storage = Storage::S3Interface.new
    @surrogates = storage.get_surrogates doc
    storage.close
  end

  def surrogate_url( doc, name )
    storage = Storage::S3Interface.new
    storage.surrogate_url(doc, name)
    storage.close
  end

  def governing_collection( object )
    if !object.governing_collection.nil?
      object.governing_collection.pid
    end
  end

  def governing_collection_solr( doc )
    if doc['is_governed_by_ssim']
      id = doc['is_governed_by_ssim'][0].gsub(/^info:fedora\//, '')
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1")
    end
    collection[0]
  end

  def get_partial_name( object )
    object.class.to_s.downcase.gsub("-"," ").parameterize("_")
  end

  def image_path ( document, suffix = "" )
    format = format?(document)

    path = "" 

    if format.eql?("unknown")
      path = "no_image.png"
    else
      path = "dri/formats/#{format}#{suffix}.png"
    end

    path
  end
    
  def reader_group_name( document )
    id = document[:is_governed_by_ssim][0].sub('info:fedora/', '')
    name = id.sub(':','_')
    return name
  end

  def count_published_items_in_collection collection_id
    solr_query = "status_ssim:published AND (is_governed_by_ssim:\"info:fedora/" + collection_id +
                 "\" OR is_member_of_collection_ssim:\"info:fedora/" + collection_id + "\" )"
    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def count_items_in_collection_by_type( collection_id, type, status )
    solr_query = "status_ssim:" + status + " AND (is_governed_by_ssim:\"info:fedora/" + collection_id +
                 "\" OR is_member_of_collection_ssim:\"info:fedora/" + collection_id + "\" ) AND " +
                 "object_type_sim:"+ type
    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def get_object_type_counts( document )
    id = document.key?(:is_governed_by_ssim) ? document[:is_governed_by_ssim][0].sub('info:fedora/', '') : document.id

    @type_counts = {}
    Settings.data.types.each do |type|
      @type_counts[type] = { :published => count_items_in_collection_by_type( id, type, "published" ) }

      if signed_in? && (can? :edit, id)
        @type_counts[type][:draft] = count_items_in_collection_by_type( id, type, "draft" )
      end

    end
  end

  def get_institutes( document )
    @collection_institutes = InstituteHelpers.get_institutes_from_solr_doc(@document)
  end


  def get_cover_image( document )
    if document[:cover_image_tesim] && document[:cover_image_tesim].first
      @cover_image = document[:cover_image_tesim].first
    elsif !document[:collection_tesim].blank?
      collection = governing_collection_solr(document)
      if collection['cover_image_tesim'] && collection['cover_image_tesim'].first
        @cover_image = collection['cover_image_tesim'].first
      else
        @cover_image = image_path( document )
      end
    else
      @cover_image = image_path( document )
    end
  end


  def get_licence( document )
    if !document[:licence_tesim].blank?
      @licence = Licence.where(:name => document[:licence_tesim]).first
    elsif !document[:collection_tesim].blank?
      collection = governing_collection_solr(document)
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

end

