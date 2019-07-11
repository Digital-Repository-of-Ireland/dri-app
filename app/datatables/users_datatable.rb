class UsersDatatable
  delegate :params, :link_to, :current_user, :t, to: :@view
  delegate :edit_user_path, to: 'UserGroup::Engine.routes.url_helpers'

  def initialize(total_users, view, approvers = nil)
    @total_users = total_users
    @view = view
    @approvers = approvers
  end

  def as_json(options = {})
    {
      recordsTotal: @total_users,
      recordsFiltered: display_users.size,
      data: data
    }
  end

  private

  def data
    display_on_page.map do |entry|
      [
        entry.id,
        entry.second_name,
        entry.first_name,
        entry.email,
        entry.created_at,
        entry.last_sign_in_at,
        entry.last_sign_in_ip,
        entry.confirmed?,
        edit_user_path(entry)
      ]
    end
  end

  def display_users
    @display_users ||= fetch_users
  end

  def fetch_users
    users = UserGroup::User.order("#{sort_column} #{sort_direction}")
    if params[:filter].present?
      users = apply_filter(users)
    end
    if params[:search][:value].present?
      users = users.where("email like :search or first_name like :search or second_name like :search", search: "%#{params[:search][:value]}%")
    end
    users
  end

  def display_on_page
    fetch_users.page(page).per(per_page)
  end

  def apply_filter(users)
    return user_filter(users) if params[:filter] == 'manage'

    case params[:filter]
    when 'confirmed'
      users.where('confirmed_at is not null')
    when 'unconfirmed'
      users.where('confirmed_at is null')
    when 'om', 'admin'
      users.joins(:groups).where("user_group_groups.name = '#{params[:filter]}'")
    when 'cm'
      approver_filter(users)
    else
      users
    end
  end

  def approver_filter(users)
    if params[:approver].present? && params[:approver] != 'All'
      users.joins(:groups).where("user_group_groups.name = 'cm'").where("user_group_memberships.approved_by = #{params[:approver]}")
    else
      users.joins(:groups).where("user_group_groups.name = 'cm'")
    end
  end

  def user_filter(users)
    users.joins(:groups).where("user_group_groups.name = 'cm'").where("user_group_memberships.approved_by = #{current_user.id}")
  end

  def page
    params[:start].to_i/per_page + 1
  end

  def per_page
    params[:length].to_i > 0 ? params[:length].to_i : 10
  end

  def sort_column
    columns = %w[ id second_name first_name email created_at last_sign_in_at last_sign_in_ip confirmed edit ]
    columns[params[:order][:'0'][:column].to_i]
  end

  def sort_direction
    params[:order][:'0'][:dir] == "desc" ? "desc" : "asc"
  end
end
