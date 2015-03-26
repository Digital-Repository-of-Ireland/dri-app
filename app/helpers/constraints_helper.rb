module ConstraintsHelper
  include Blacklight::RenderConstraintsHelperBehavior

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
  def render_constraint_element(label, value, options = {})
  	if (value.include?("cdateRange") || value.include?("pdateRange") || value.include?("sdateRange"))
  	  # cdateRange:["-9999 2002.5" TO "2003.5 9999"]
  	  sdate = value.match(/"-9999 (.*)" TO "(.*) 9999"/)[1].clone
  	  edate = value.match(/"-9999 (.*)" TO "(.*) 9999"/)[2].clone
      sdate_d = (sdate.to_f + 0.5).to_s.gsub!(".0", "")
      edate_d = (edate.to_f - 0.5).to_s.gsub!(".0", "")
      if sdate_d == edate_d
      	date_display = sdate_d
      else
      	date_display = sdate_d << " - " << edate_d
      end
      return render(:partial => "catalog/constraints_element", :locals => {:label => label, 
      	:value => date_display, 
      	:options => options})    
  	end
    render(:partial => "catalog/constraints_element", :locals => {:label => label, :value => value, :options => options})    
  end

end