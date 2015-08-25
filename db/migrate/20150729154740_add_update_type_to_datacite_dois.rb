class AddUpdateTypeToDataciteDois < ActiveRecord::Migration
  def change
    add_column :datacite_dois, :update_type, :string
  end
end
