class CreateIngestStatuses < ActiveRecord::Migration
  def change
    create_table :ingest_statuses do |t|
      t.string :batch_id, index: true
      t.string :asset_id, index: true
      t.string :status

      t.timestamps
    end
  end
end
