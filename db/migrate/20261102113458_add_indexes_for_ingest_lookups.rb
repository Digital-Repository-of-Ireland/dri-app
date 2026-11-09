class AddIndexesForIngestLookups < ActiveRecord::Migration[8.0]
  def change
    add_index :dri_batch_ingest_ingest_batches, :user_ingest_id,
              name: 'index_ingest_batches_on_user_ingest_id'

    add_index :dri_batch_ingest_master_files, [:media_object_id, :status_code],
              name: 'index_master_files_on_media_object_id_and_status_code'
  end
end
