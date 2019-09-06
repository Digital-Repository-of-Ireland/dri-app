class CreateDataciteDois < ActiveRecord::Migration[4.2]
  def change
    create_table :datacite_dois do |t|
      t.string :object_id
      t.string :modified
      t.string :mod_version

      t.timestamps
    end
  end
end
