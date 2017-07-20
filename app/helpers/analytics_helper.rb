module AnalyticsHelper

  def get_custom_vars()
    if @document.present? && @document.published?
      custom_vars = [GA::Events::SetCustomDimension.new(1, @document.root_collection_id)]
      if @document.depositing_institute.present?
        custom_vars.push(GA::Events::SetCustomDimension.new(2, @document.depositing_institute.name))
      end
    end
    custom_vars
  end

end

