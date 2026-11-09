class AddMetadataToMasterFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :dri_batch_ingest_master_files, :metadata, :boolean
  end
end
