# frozen_string_literal: true
class MyCollectionsSearchBuilder < SearchBuilder
  # This applies appropriate access controls to all solr queries
  self.default_processor_chain += [:only_manage_or_edit_access]

  def only_manage_or_edit_access(solr_parameters)
    solr_parameters[:fq] ||= []
    return if current_ability&.current_user && current_ability.current_user.is_admin?

    # any objects that the user can edit or manage
    solr_parameters[:fq] << "(" + apply_manage_or_edit_permissions + ")"

    Rails.logger.debug("Solr parameters: #{ solr_parameters.inspect }")
  end
end

