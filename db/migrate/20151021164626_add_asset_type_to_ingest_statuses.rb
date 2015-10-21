class AddAssetTypeToIngestStatuses < ActiveRecord::Migration
  def change
    add_column :ingest_statuses, :asset_type, :string
  end
end
