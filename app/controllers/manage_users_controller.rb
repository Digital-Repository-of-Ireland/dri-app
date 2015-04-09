class ManageUsersController < ApplicationController


  def create

    if ( signed_in? && ( current_user.is_admin? || current_user.is_om? ))
      user = UserGroup::User.find_by_email(params[:user])
      if user.present?
        group_id = UserGroup::Group.find_by_name("cm").id
        membership = user.join_group(group_id)
        membership.approved_by = current_user.id
        membership.save
        flash[:notice] = t('dri.flash.notice.manager_user_created', :email => params[:user])
      else
        flash[:notice] = t('dri.flash.notice.manager_user_invalid', :email => params[:user])
      end
    else
      flash[:error] = t('dri.flash.error.manager_user_permission')
    end

    respond_to do |format|
      format.html  {
        render :action => "new"
      }
    end

  end

end
