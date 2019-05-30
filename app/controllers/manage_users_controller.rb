class ManageUsersController < ApplicationController
  def create
    if signed_in? && (current_user.is_admin? || current_user.is_om?)
      user = UserGroup::User.find_by_email(params[:user].strip)
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
        group_id = UserGroup::Group.find_by_name(group).id
        membership = user.join_group(group_id)
        membership.approved_by = current_user.id
        membership.save
      end
    end
end
