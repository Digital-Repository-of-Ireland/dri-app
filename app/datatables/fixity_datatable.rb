class FixityDatatable
  delegate :current_user, :params, :object_history_path, :link_to, :fixity_check_path, to: :@view
  
  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      recordsTotal: collections.size,
      recordsFiltered: collections.size,
      data: data
    }
  end

private

  def data
    display_on_page.map do |collection|
      fixity = fixity_info(collection)

      [
       link_to(collection['title_tesim'].first, object_history_path(collection.id)),
       fixity[:time],
       fixity[:verified],
       fixity_check_path(collection.id),
       collection.total_objects_count,
       total_checked(collection.id, fixity[:time])
      ]
    end
  end

  def collections
    @collections || load_collections
  end

  def fixity_info(collection)
    history = ObjectHistory.new(object: collection)
    history.fixity
  end

  def display_on_page
    Kaminari.paginate_array(collections).page(page).per(per_page)
  end 

  def page
    params[:start].to_i/per_page + 1
  end

  def per_page
    params[:length].to_i > 0 ? params[:length].to_i : 10
  end
  
  def load_collections
    collections = []

    solr_query = Solr::Query.new(
      "*:*",
      100,
      { fq: ["+#{Solrizer.solr_name('is_collection', :facetable, type: :string)}:true",
            "-#{Solrizer.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"]}
    )

    solr_query.each { |object| collections.push(object) }

    collections
  end

  def total_checked(id, start_time)
    FixityCheck.where(collection_id: id).where("created_at >= '#{start_time}'").count
  end
    
end
