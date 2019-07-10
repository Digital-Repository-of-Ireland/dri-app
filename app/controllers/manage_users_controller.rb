class ManageUsersController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def new
    unless current_user.is_admin? || current_user.is_om?
      raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied'))
    end

    respond_to do |format|
      format.html
      format.json do
        render json: UsersDatatable.new(user_count, view_context)
      end
    end
  end

  def create
    if current_user.is_admin? || current_user.is_om?
      user = UserGroup::User.find_by(email: params[:user].strip)
      if user.present?
        groups = ['cm']
        groups << 'om' if current_user.is_admin? && assign_om?

        add_groups_to_user(user, groups)

        flash[:notice] = t('dri.flash.notice.manager_user_created', email: params[:user])
      else
        flash[:error] = t('dri.flash.error.manager_user_invalid', email: params[:user])
      end
    else
      flash[:error] = t('dri.flash.error.manager_user_permission')
    end

    respond_to do |format|
      format.html { render action: 'new' }
    end
  end

  private
    def assign_om?
       params[:type].present? && params[:type] == 'om'
    end

    def add_groups_to_user(user, groups)
      groups.each do |group|
        group_id = UserGroup::Group.find_by(name: group).id
        membership = user.join_group(group_id)
        membership.approved_by = current_user.id
        membership.save
      end
    end

    def user_count
      return UserGroup::User.joins(:groups).where("user_group_groups.name = 'cm'").where("user_group_memberships.approved_by = #{current_user.id}").count
    end
end
