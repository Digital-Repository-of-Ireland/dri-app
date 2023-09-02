class VisibilityJob
  @queue = :visibility

  def self.perform(object_id)
    o = DRI::DigitalObject.find_by_alternate_id(object_id)
    o.visibility = read_permissions(SolrDocument.find(object_id))
    o.save
     
    update_collection_visibility(o) if o.collection?
  end

  def self.update_collection_visibility(collection)
    # objects within the collection that inherit access controls
    q_str = "ancestor_id_ssim:\"#{collection.alternate_id}\""
    f_query = [
                "-read_access_group_ssim:[* TO *]",
                "-visibility_ssi:#{collection.visibility}"
              ]

    query = Solr::Query.new(q_str, 1000, fq: f_query)
    query.each do |object|
      o = DRI::DigitalObject.find_by_alternate_id(object.id)
      o.visibility = collection.visibility
      o.save
    end
  end

  def self.read_permissions(object)
    read_groups = object.ancestor_field('read_access_group_ssim')

    case read_groups
    when ['registered']
      'logged-in'
    when ['public']
      'public'
    else
      'restricted'
    end
  end
end