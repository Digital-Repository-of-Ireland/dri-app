module SearchHelper
  def get_params_to_hide(current_params)
    params_to_hide = current_params.clone
    params_to_hide.delete(:q)
    params_to_hide.delete(:search_field)
    params_to_hide.delete(:qt)
    params_to_hide.delete(:page)
    params_to_hide.delete(:utf8)
    params_to_hide.delete(:id)
    return params_to_hide
  end
end