class AddAllowFullCollectionExportToCollectionConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :collection_configs, :allow_full_collection_export, :boolean, default: false, null: false
  end
end
