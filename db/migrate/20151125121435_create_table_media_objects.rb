class CreateTableMediaObjects < ActiveRecord::Migration[4.2]
  def change
    create_table :dri_batch_ingest_media_objects do |t|
      t.references :ingest_batch, index: { name: 'ingest_batch_idx' }
      t.string :collection
      t.timestamps null: false
    end

    add_foreign_key :dri_batch_ingest_media_objects, :dri_batch_ingest_ingest_batches, column: :ingest_batch_id, name: 'ingest_batch_fk'
  end
end
