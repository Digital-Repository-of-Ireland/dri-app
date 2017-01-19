class UserActivityDatatable
  delegate :params, :link_to, to: :@view
  delegate :user_path, to: 'UserGroup::Engine.routes.url_helpers'

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      recordsTotal: PaperTrail::Version.count,
      recordsFiltered: audit.count,
      data: data
    }
  end

private

  def data
    display_on_page.map do |entry|
      [
       entry.created_at,
       entry.item_type,
       item_id(entry),
       entry.event,
       entry.object
      ]
    end
  end

  def audit
    @audit ||= fetch_audit
  end

  def fetch_audit
    audit = PaperTrail::Version.order("#{sort_column} #{sort_direction}")
    if params[:search][:value].present?
      audit = audit.where("object like :search or event like :search or created_at like :search", search: "%#{params[:search][:value]}%")
    end
    audit
  end

  def display_on_page 
    fetch_audit.page(page).per(per_page) 
  end 

  def page
    params[:start].to_i/per_page + 1
  end

  def per_page
    params[:length].to_i > 0 ? params[:length].to_i : 10
  end

  def sort_column
    columns = %w[created_at item_type item_id event object]
    columns[params[:order][:'0'][:column].to_i]
  end

  def sort_direction
    params[:order][:'0'][:dir] == "desc" ? "desc" : "asc"
  end

  def item_id(entry)
    if entry.item_type == 'UserGroup::User'
        user = UserGroup::User.find(entry.item_id)
        user.nil? ? entry.item_id : link_to(UserGroup::User.find(entry.item_id).to_s, user_path(entry.item_id))
    elsif entry.item_type == 'UserGroup::Membership'
      entry.item_id
    end
  end
end
