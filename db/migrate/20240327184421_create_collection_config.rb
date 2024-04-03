class CreateCollectionConfig < ActiveRecord::Migration[6.1]
  def change
    create_table :collection_configs do |t|
      t.boolean :allow_export
      t.string :collection_id

      t.timestamps
    end
    add_index :collection_configs, :collection_id
  end
end
