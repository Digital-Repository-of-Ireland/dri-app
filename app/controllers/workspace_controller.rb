class WorkspaceController < ApplicationController

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def index
    @tasks_count = UserBackgroundTask.where(user_id: current_user.id).count
    @manage_collections_count = manage_or_edit_collections_count(type: :manage)
    @edit_collections_count = manage_or_edit_collections_count(type: :edit)
    @collection_count = @manage_collections_count + @edit_collections_count
  end

  def collections
    collections = UserCollections.new(user: current_user)
    @collection_data = Kaminari.paginate_array(collections.collections_data).page(params[:page]).per(5)
  end

  def readers
    query = "(_query_:\"{!join from=id to=ancestor_id_ssim}manager_access_person_ssim:#{current_user.email}\" OR manager_access_person_ssim:#{current_user.email})"
    fq = ["+is_collection_ssi:true"]
    fq << '+read_access_group_ssim:[* TO *]'
    fq << '-read_access_group_ssim:public'

    query = Solr::Query.new(query, 100, fq: fq)
    manage_collections = query.to_a

    group_memberships = manage_collections.map do |collection|
      group = UserGroup::Group.find_by(name: collection.id)
      next unless group

      pending_memberships = group.pending_memberships
      memberships = group.full_memberships
      next if pending_memberships.blank? && memberships.blank?

      { collection: collection, pending: pending_memberships, approved: memberships }
    end.compact

    @read_group_memberships = Kaminari.paginate_array(group_memberships).page(params[:page])
  end

  private

    def manage_or_edit_collections_count(type: nil)
      manage_query = "(_query_:\"{!join from=id to=ancestor_id_ssim}manager_access_person_ssim:#{current_user.email}\" OR manager_access_person_ssim:#{current_user.email})"
      edit_query = "(_query_:\"{!join from=id to=ancestor_id_ssim}edit_access_person_ssim:#{current_user.email}\" OR edit_access_person_ssim:#{current_user.email})"

      query = case type
              when :manage
                manage_query
              when :edit
                edit_query
              else
                "#{manage_query} OR #{edit_query}"
              end
      fq = ["+is_collection_ssi:true"]

      Solr::Query.new(query, 100, fq: fq).count
    end
end
