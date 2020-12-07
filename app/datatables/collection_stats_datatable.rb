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
       collection.total_objects_count,
       number_to_human_size(stats[:size]),
      ]
    end
  end

  def collections
    @collections || load_collections
  end

  def stats_info(collection)
    stats = Solr::Query.new(
              "{!join from=id to=isPartOf_ssim}root_collection_id_ssi:#{collection.id} && is_collection_ssi:false",
              100,
              { stats: true, 'stats.field' => 'file_size_isi' }
            ).get

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
    solr_query = Solr::Query.new(
                   "*:*",
                   100,
                   { fq: ["is_collection_ssi:true",
                         "-ancestor_id_ssim:[* TO *]"]}
                 )
    solr_query.to_a
  end
end
