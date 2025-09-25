class ActivityDatatable
  delegate :params, :h, :link_to, :my_collections_path, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      recordsTotal: VersionCommitter.count,
      recordsFiltered: versions.count,
      data: data
    }
  end

private

  def data
    display_on_page.map do |version|
      update = update_info(version)
      link = my_collections_path(update[:updated_id])

      [
        update[:updated_at],
        link_to(update[:updated_id], link),
        update[:version_id],
        link_to(update[:collection_title], my_collections_path(update[:collection_id])),
        update[:committer],
        update[:event]
      ]
    end
  end

  def versions
    @versions ||= fetch_versions
  end

  def fetch_versions
    versions = VersionCommitter.where('created_at >= ?', 1.week.ago).order("#{sort_column} #{sort_direction}")
    if params[:search][:value].present?
      versions = versions.where("committer_login like :search or created_at like :search", search: "%#{params[:search][:value]}%")
    end
    versions
  end

  def display_on_page
    fetch_versions.page(page).per(per_page)
  end

  def page
    params[:start].to_i/per_page + 1
  end

  def per_page
    params[:length].to_i > 0 ? params[:length].to_i : 10
  end

  def sort_column
    columns = %w[created_at obj_id version_id collection committer_login event]
    columns[params[:order][:'0'][:column].to_i]
  end

  def sort_direction
    params[:order][:'0'][:dir] == "desc" ? "desc" : "asc"
  end

  def update_info(version)
    info = {}
    info[:committer] = version.committer_login
    info[:updated_at] = version.created_at
    info[:updated_id] = version.obj_id
    info[:version_id] = version.version_id
    info[:event] = version.event

    # get object solr info
    doc = SolrDocument.find(version.obj_id)
    if doc
      ids = doc['isGovernedBy_ssim'] || [doc['id']]
      titles = doc['collection_tesim'] || doc['title_tesim']
      info[:collection_id] = ids.first
      info[:collection_title] = titles.first
    else
      info[:collection_id] = ''
      info[:collection_title] = ''
    end

    info
  end
end
