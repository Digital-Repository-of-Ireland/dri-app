class ChangeTypeOfFileLocation < ActiveRecord::Migration[5.2]
  def up
    change_column :dri_batch_ingest_master_files, :file_location, :text
  end

  def down
    change_column :dri_batch_ingest_master_files, :file_location, :string
  end
end
