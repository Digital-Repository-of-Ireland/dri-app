module BatchTranslator
  # translate button text to input id 
  # on _form_metadata_qualifieddublincore.html.erb e.g. collections/new
  def button_to_input_id(button_text)
    case button_text
      when /^Add Coverage$/
        "batch_coverage]["
      when /^Add Place$/
        "batch_geographical_coverage]["
      when /^Add Temporal Coverage$/
        "batch_temporal_coverage]["
      when /^Add Subject$/
        "batch_subject]["
    end
  end
end


World(BatchTranslator)
