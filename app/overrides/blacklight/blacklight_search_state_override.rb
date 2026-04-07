Blacklight::SearchState.class_eval do
  def to_hash
    params.deep_dup.with_indifferent_access
  end
  alias to_h to_hash
end
