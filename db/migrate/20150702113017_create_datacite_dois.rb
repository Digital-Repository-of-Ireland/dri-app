class CreateDataciteDois < ActiveRecord::Migration
  def change
    create_table :datacite_dois do |t|
      t.string :object_id
      t.string :modified
      t.string :mod_version

      t.timestamps
    end
  end
end
