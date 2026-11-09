class CreateTableMasterFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :dri_batch_ingest_master_files do |t|
      t.references :media_object, index: true
      t.string :status_code
      t.string :file_size
      t.string :file_location
      t.boolean :preservation
      t.text :download_spec
      t.timestamps null: false
    end

    add_foreign_key :dri_batch_ingest_master_files, :dri_batch_ingest_media_objects, column: :media_object_id
  end
end
