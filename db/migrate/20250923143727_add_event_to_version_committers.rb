class AddEventToVersionCommitters < ActiveRecord::Migration[7.2]
  def change
    add_column :version_committers, :event, :string
  end
end
