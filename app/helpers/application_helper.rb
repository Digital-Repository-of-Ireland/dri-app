module ApplicationHelper
  require 'storage/s3_interface'

  # Returns the file that should be delivered to the user
  #   # based on their access rights and the policies and available
  #     # surrogates of the object
  def get_delivery_file doc
    if can? :read, doc.id
      get_files(doc)
      masterfile = @files[0] unless @files.nil?
      
      @asset = nil

      if (!masterfile)
        @asset = "no file"
      elsif (can?(:read_master, doc.id))
        @asset = "masterfile"
      else
        delivery_file = Storage::S3Interface.deliverable_surrogate?(doc)

        if (!delivery_file.blank?)
          @asset = Storage::S3Interface.get_link_for_surrogate(doc, delivery_file)
        elsif (delivery_file.blank?)
          @asset = "no file"
        else
          @asset = "no permission"
        end
      end
    else
      @asset = "no permission"
    end
  end

  def get_files doc
    @files = ActiveFedora::Base.find(doc.id, {:cast => true}).generic_files
    ""
  end

  def get_surrogates doc
    @surrogates = Storage::S3Interface.get_surrogates doc
  end

  def get_collections
    results = Array.new
    #solr_query = "+object_type_sim:Collection +depositor_sim:*"
    solr_query = "+object_type_sim:Collection"
    solr_query += " AND (" + generate_manager_permission_filters().join(" OR ") + ")" unless current_user && current_user.is_admin?

    result_docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "500", :fl => "id,title_tesim")
    result_docs.each do | doc |
      results.push([doc["title_tesim"][0], doc['id']])
    end

    return results
  end

  def get_governing_collection( object )
    if !object.governing_collection.nil?
      object.governing_collection.pid
    end
  end

  def get_partial_name( object )
    object.class.to_s.downcase.gsub("-"," ").parameterize("_")
  end

  def is_collection?( document )
    document["type_ssm"].first.casecmp("collection") == 0 ? true : false
  end
  
  def count_published_items_in_collection collection_id
    solr_query = "status_ssim:published AND (is_governed_by_ssim:\"info:fedora/" + collection_id +
                 "\" OR is_member_of_collection_ssim:\"info:fedora/" + collection_id + "\" )"
    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def count_published_items_in_collection_by_type( collection_id, type )
    solr_query = "status_ssim:published AND (is_governed_by_ssim:\"info:fedora/" + collection_id +
                 "\" OR is_member_of_collection_ssim:\"info:fedora/" + collection_id + "\" ) AND " +
                 "object_type_tesim:"+ type
    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def get_object_type_counts( document )
    id = document.key?(:is_governed_by_ssim) ? document[:is_governed_by_ssim][0].sub('info:fedora/', '') : document.id

    @type_counts = {}
    Settings.data.types.each do |type|
      @type_counts[type] =  count_published_items_in_collection_by_type( id, type )
    end
  end

  def generate_manager_permission_filters()
      filters = []

      user_roles = current_ability.user_groups
      user_roles |= ['public']

      string_user_roles = "("+user_roles.join(" OR ")+")"

      permission_types = [ "manager", "edit" ]

      permission_types.each do |type|
        permission_query = escape_filter(ActiveFedora::SolrService.solr_name("#{type}_access_group", Hydra::Datastream::RightsMetadata.indexer), string_user_roles)

        if current_user && current_user.user_key.present?
          permission_query += " OR " + escape_filter(ActiveFedora::SolrService.solr_name("#{type}_access_person", Hydra::Datastream::RightsMetadata.indexer), current_user.user_key)
        end

        permission_query = "_query_:\"{!join from=id to=governing_id_sim}" + permission_query + "\" OR " +
                           "("+permission_query+")"

        filters << permission_query
      end

      filters
  end
    
  def escape_filter(key, value)
    [key, value.gsub('/', '\/')].join(':')
  end

end

