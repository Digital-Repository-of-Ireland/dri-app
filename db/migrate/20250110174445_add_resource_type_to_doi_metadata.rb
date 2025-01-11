class AddResourceTypeToDoiMetadata < ActiveRecord::Migration[7.1]
  def change
    add_column :doi_metadata, :resource_type, :text
  end
end
