class AddSubcollectionSortToCollectionConfig < ActiveRecord::Migration[7.2]
  def change
    add_column :collection_configs, :subcollection_sort, :string
  end
end
