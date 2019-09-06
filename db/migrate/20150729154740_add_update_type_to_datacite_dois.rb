class AddUpdateTypeToDataciteDois < ActiveRecord::Migration[4.2]
  def change
    add_column :datacite_dois, :update_type, :string
  end
end
