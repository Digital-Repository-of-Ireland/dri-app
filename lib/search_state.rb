class SearchState < Blacklight::SearchState
  def query_param
  	params[:q_ws]
  end
end