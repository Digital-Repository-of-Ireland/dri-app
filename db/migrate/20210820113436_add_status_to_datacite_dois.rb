class AddStatusToDataciteDois < ActiveRecord::Migration[5.2]
  def change
    add_column :datacite_dois, :status, :string
  end
end
