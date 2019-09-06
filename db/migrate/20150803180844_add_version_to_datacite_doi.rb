class AddVersionToDataciteDoi < ActiveRecord::Migration[4.2]
  def change
    add_column :datacite_dois, :version, :int
  end
end
