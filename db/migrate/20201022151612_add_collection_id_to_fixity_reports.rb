class AddCollectionIdToFixityReports < ActiveRecord::Migration[5.2]
  def change
    add_column :fixity_reports, :collection_id, :string
    add_index :fixity_reports, :collection_id
  end
end
