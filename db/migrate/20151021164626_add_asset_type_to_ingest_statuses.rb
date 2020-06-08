class AddAssetTypeToIngestStatuses < ActiveRecord::Migration[4.2]
  def change
    add_column :ingest_statuses, :asset_type, :string
  end
end
