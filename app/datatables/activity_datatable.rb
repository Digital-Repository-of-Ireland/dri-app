class ActivityDatatable
  delegate :params, :h, :link_to, :catalog_path, to: :@view

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

      [
        update[:updated_at],
        link_to(update[:updated_id], catalog_path(update[:updated_id])),
        update[:type],
        link_to(update[:collection_title], catalog_path(update[:collection_id])),
        update[:committer],
        update[:status]
      ]
    end
  end

  def versions
    @versions ||= fetch_versions
  end

  def fetch_versions
    versions = VersionCommitter.order("#{sort_column} #{sort_direction}")
    if params[:search][:value].present?
      versions = versions.where("committer_login like :search", search: "%#{params[:search][:value]}%")
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
    columns = %w[created_at committer_login]
    columns[params[:order][:'0'][:column].to_i]
  end

  def sort_direction
    params[:order][:'0'][:dir] == "desc" ? "desc" : "asc"
  end

  def update_info(version)
    info = {}
    info[:committer] = version.committer_login
    info[:updated_at] = version.created_at
    
    updated_obj = version.obj_id
    updated_version = version.version_id

    if updated_obj
      info[:updated_id] = updated_obj
      info[:type] = 'Object'
      
      # get object solr info
      doc = solr_doc_for_id(updated_obj)
      if doc
        ids = doc['collection_id_tesim'] || [doc['id']]
        titles = doc['collection_tesim'] || doc['title_tesim']
        info[:collection_id] = ids.first
        info[:collection_title] = titles.first
      else
        info[:collection_id] = ''
        info[:collection_title] = ''
        info[:status] = "Not found"
      end

    elsif updated_version
      # get gf solr info
      gf_id = extract_id(updated_version)
      info[:updated_id] = gf_id
      info[:type] = 'File'

      doc = solr_doc_for_id(gf_id)
      if doc
        parent_id = doc['isPartOf_ssim'].first
        parent = solr_doc_for_id(parent_id)
        info[:collection_id] = parent['collection_id_tesim'].first
        info[:collection_title] = parent['collection_tesim'].first
      else
        info[:collection_id] = ''
        info[:collection_title] = ''
        info[:status] = "Not found"
      end    
    end

    info
  end

  def extract_id(vid)
    uri = URI(vid)
    uri.path.split('content')[0].split('/').last
  end

  def solr_doc_for_id(id)
    result = ActiveFedora::SolrService.query("id:#{id}")
    doc = result.present? ? result.first : nil
  end

end