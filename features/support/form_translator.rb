module FormTranslator

  def form_to_id(form_name)

    case form_name

    when /create new licence/
      "dri_new_licence_form"

    else "Unknown"

    end
  end

end
World(FormTranslator)
