class ReviewJob
  include Resque::Plugins::Status

  @queue = :review

  def queue
    :review
  end

  def name
    'ReviewJob'
  end

  def perform
    collection_id = options['collection_id']
    user_id = options['user_id']

    # get objects within this collection, not including sub-collections
    q_str = "#{ActiveFedora.index_field_mapper.solr_name('collection_id', :facetable, type: :string)}:\"#{collection_id}\""
    q_str += " AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:draft"
    f_query = "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:false"

    query = Solr::Query.new(q_str, 100, fq: f_query)

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = ActiveFedora::Base.find(object["id"], {cast: true})
        if o.status == 'draft'
          o.status = 'reviewed'
          o.save
        end     
      end
    end

    collection = ActiveFedora::Base.find(collection_id, cast: true)

    # Need to set sub-collection to reviewed
    if subcollection?(collection)
      collection.status = 'reviewed'
      collection.save
    end
  end

  def subcollection?(object)
    object.collection? && !object.root_collection?
  end

end
