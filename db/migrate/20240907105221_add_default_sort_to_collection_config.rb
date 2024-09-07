class AddDefaultSortToCollectionConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :collection_configs, :default_sort, :string
  end
end
