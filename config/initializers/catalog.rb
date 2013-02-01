# -*- encoding : utf-8 -*-
module Blacklight::Catalog   

  def search_action_url
    url_for(:controller => 'catalog', :action => 'index', :only_path => true)
  end

end
