class CollectionStatsDatatable
  delegate :current_user, :params, :my_collections_path, :number_to_human_size, :link_to, to: :@view
  
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
      stats = stats_info(collection)

      [
       link_to(collection['title_tesim'].first, my_collections_path(collection.id)),
       collection.total_objects,
       number_to_human_size(stats[:size]),
      ]
    end
  end

  def collections
    @collections || load_collections
  end

  def stats_info(collection)
    stats = ActiveFedora::SolrService.get("{!join from=id to=isPartOf_ssim}root_collection_id_sim:#{collection.id} && is_collection_sim:false", 
      stats: true, 'stats.field' => 'file_size_isi')

    if stats.present? && stats['stats']['stats_fields'].present? && stats['stats']['stats_fields']['file_size_isi'].present?
      total = stats['stats']['stats_fields']['file_size_isi']['sum']
    else
      total = 0
    end

    { size: total }
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
      { fq: ["+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true",
            "-#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"]}
    )

    solr_query.each { |object| collections.push(object) }

    collections
  end
end
