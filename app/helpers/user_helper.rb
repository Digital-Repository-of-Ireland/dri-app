module UserHelper
  #TO BE DELETED once the functionality has been developed
  def get_collection_permission
    fake_data = [{:collection_title => "Fake Collection 1", :permission => "Collection Manager"}, {:collection_title => "Fake Collection 2", :permission => "Editor"}]
    return fake_data
  end
end