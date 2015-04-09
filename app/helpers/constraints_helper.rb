module ConstraintsHelper
  include Blacklight::RenderConstraintsHelperBehavior

  ##
  # OVERRIDEN. Render a single facet's constraint
  #
  # @param [String] facet field
  # @param [Array<String>] selected facet values
  # @param [Hash] query parameters
  # @return [String]
  def render_filter_element(facet, values, localized_params)
    # Overrride BL's render_filter_element
    # When creating remove filter links exclude the date range added parameters, if present
    # Otherwise the filter gets removed but the parameters stay in the URL
    if (facet == "cdateRange")
      excluded_params = [:c_date, :p_date, :s_date, :year_from, :year_to]
      new_localized_params = localized_params.clone
      new_localized_params.except!(*excluded_params)

      super(facet, values, new_localized_params)
    else
      super(facet, values, localized_params)
    end
  end
  ##
  # OVERRIDE. Check if the query has any constraints defined (a query, facet, etc)
  # our search points by ID  are :q_text for DRI search text box, :f for facets and :q_date for date range search
  # @param [Hash] query parameters
  # @return [Boolean]
  #def query_has_constraints?(localized_params = params)
    #!(localized_params[:q_text].blank? and localized_params[:f].blank?) || !(localized_params[:q_date].blank? and localized_params[:f].blank?)
  #end

  ##
  # OVERRIDE Render the query constraints
  #
  # @param [Hash] query parameters
  # @return [String]
  #def render_constraints_query(localized_params = params)
    # So simple don't need a view template, we can just do it here.
    #scope = localized_params.delete(:route_set) || self
    #return "".html_safe if (localized_params[:q_text].blank? && localized_params[:q_date].blank?)
    #if (!localized_params[:q_text].blank?)
    #  render_constraint_element(constraint_query_label(localized_params),
    #    localized_params[:q_text],
    #    :classes => ["query"],
    #    :remove => scope.url_for(localized_params.merge(:q_text=>nil, :action=>'index')))
    #end
    #if (!localized_params[:q_date].blank?)
    #  render_constraint_element(constraint_query_label(localized_params),
    #    localized_params[:q_date],
    #    :classes => ["query"],
    #    :remove => scope.url_for(localized_params.merge(:q_date=>nil, :action=>'index')))
    #end
  #end
  
  # OVERRIDE Render a label/value constraint on the screen. Can be called
  # by plugins and such to get application-defined rendering.
  #
  # Can be over-ridden locally to render differently if desired,
  # although in most cases you can just change CSS instead.
  #
  # Can pass in nil label if desired.
  #
  # @param [String] label to display
  # @param [String] value to display
  # @param [Hash] options
  # @option options [String] :remove url to execute for a 'remove' action
  # @option options [Array<String>] :classes an array of classes to add to container span for constraint.
  # @return [String]
  #def render_constraint_element(label, value, options = {})
  #  binding.pry
  # 	if (value.include?("cdateRange") || value.include?("pdateRange") || value.include?("sdateRange"))
  #	  # cdateRange:["-9999 2002.5" TO "2003.5 9999"]
  # 	  sdate = value.match(/"-9999 (.*)" TO "(.*) 9999"/)[1].clone
  #	  edate = value.match(/"-9999 (.*)" TO "(.*) 9999"/)[2].clone
  #    sdate_d = (sdate.to_f + 0.5).to_s.gsub!(".0", "")
  #    edate_d = (edate.to_f - 0.5).to_s.gsub!(".0", "")
  #    if sdate_d == edate_d
  #    	date_display = sdate_d
  #    else
  #    	date_display = sdate_d << " - " << edate_d
  #    end
  #    return render(:partial => "catalog/constraints_element", :locals => {:label => label, 
  #    	:value => date_display, 
  #    	:options => options})    
  # 	end
  #  render(:partial => "catalog/constraints_element", :locals => {:label => label, :value => value, :options => options})    
  #end

end