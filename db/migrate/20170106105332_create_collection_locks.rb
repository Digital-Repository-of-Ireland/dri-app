class CreateCollectionLocks < ActiveRecord::Migration
  def change
    create_table :collection_locks do |t|
      t.string :collection_id

      t.timestamps null: false
    end
  end
end
