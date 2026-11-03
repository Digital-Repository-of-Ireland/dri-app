class AddReviewToIngestBatches < ActiveRecord::Migration[8.0]
  def up
    add_column :dri_batch_ingest_ingest_batches, :confirmed_at, :datetime
    add_column :dri_batch_ingest_ingest_batches, :report, :text, limit: 16.megabytes - 1
    add_column :dri_batch_ingest_user_ingests, :error, :text
    execute 'UPDATE dri_batch_ingest_ingest_batches SET confirmed_at = created_at'
  end

  def down
    remove_column :dri_batch_ingest_ingest_batches, :confirmed_at
    remove_column :dri_batch_ingest_ingest_batches, :report
    remove_column :dri_batch_ingest_user_ingests, :error
  end
end
