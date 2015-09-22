class AddVersionToDataciteDoi < ActiveRecord::Migration
  def change
    add_column :datacite_dois, :version, :int
  end
end
