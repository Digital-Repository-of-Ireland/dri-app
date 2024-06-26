class AddSupportedToCopyrights < ActiveRecord::Migration[6.1]
  def change
    add_column :copyrights, :supported, :boolean
  end
end
