class ManageUsersController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!
  before_action :om?

  def new
    @organisations = organisations(current_user) if current_user.is_om?

    respond_to do |format|
      format.html
      format.json do
        render json: UsersDatatable.new(user_count, view_context)
      end
    end
  end

  def create
    user = UserGroup::User.find_by(email: params[:user].strip)
    if user.present?
      groups = ['cm']
      groups << 'om' if current_user.is_admin? && assign_om?

      add_groups_to_user(user, groups)

      flash[:notice] = t('dri.flash.notice.manager_user_created', email: params[:user])
    else
      flash[:error] = t('dri.flash.error.manager_user_invalid', email: params[:user])
    end

    respond_to do |format|
      format.html { render action: 'new' }
    end
  end

  def show
    user = UserGroup::User.find(params[:user_id])
    raise DRI::Exceptions::BadRequest unless collection_manager?(user) && approved_by_current_user?(user)
    @user_details = {}
    @user_details[:id] = user.id
    @user_details[:name] = user.full_name
    @user_details[:email] = user.email
    @user_details[:created_at] = user_collection_manager_membership(user).created_at

    @users_collections = Solr::Query.new("manager_access_person_ssim:\"#{user.email}\"", 100, { fq: '-isGovernedBy_ssim:[* TO *]' }).to_a
  end

  def destroy
    user = UserGroup::User.find(params[:user_id])
    if user.present?
      remove_group_from_user(user, UserGroup::Group.find_by(name: 'cm'))

      flash[:notice] = t('dri.flash.notice.manager_user_removed', email: user.email)
    else
      flash[:error] = t('user_groups.shared.errors.user')
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

  def remove_group_from_user(user, group)
    user.leave_group(group)
  end

  def approved_by_current_user?(user)
    user_collection_manager_membership(user).approved_by == current_user.id
  end

  def collection_manager?(user)
    user.member?(UserGroup::Group.find_by(name: 'cm').id)
  end

  def user_collection_manager_membership(user)
    @user_collection_manager_membership ||= user.memberships.find_by(group_id: UserGroup::Group.find_by(name: 'cm'))
  end

  def user_count
    UserGroup::User.joins(:groups).where("user_group_groups.name = 'cm'").where("user_group_memberships.approved_by = #{current_user.id}").count
  end

  def organisations(user)
    Institute.joins(:organisation_users).where('organisation_users.user_id = ?', user.id).to_a
  end

  def om?
    return true if current_user.is_admin?
    raise Blacklight::AccessControls::AccessDenied, t('dri.views.exceptions.access_denied') unless current_user.is_om?
  end
end
