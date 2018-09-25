class WorkspaceController < ApplicationController

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def index
    @tasks_count = UserBackgroundTask.where(user_id: current_user.id).count
    @collection_count = manage_or_edit_collections_count
  end

  private

    def manage_or_edit_collections_count
      query = "(_query_:\"{!join from=id to=ancestor_id_sim}manager_access_person_ssim:#{current_user.email}\" OR manager_access_person_ssim:#{current_user.email})"
      query += " OR (_query_:\"{!join from=id to=ancestor_id_sim}edit_access_person_ssim:#{current_user.email}\" OR edit_access_person_ssim:#{current_user.email})"

      fq = ["+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true"]

      if params[:governing].present?
        fq << "+#{ActiveFedora.index_field_mapper.solr_name('isGovernedBy', :stored_searchable, type: :symbol)}:#{params[:governing]}"
      end
      fq << "+#{ActiveFedora.index_field_mapper.solr_name('has_model', :stored_searchable, type: :symbol)}:\"DRI::QualifiedDublinCore\""

      ActiveFedora::SolrService.count(query, fq: fq)
    end

end
