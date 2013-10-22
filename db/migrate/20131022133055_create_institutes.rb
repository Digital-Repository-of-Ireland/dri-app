class CreateInstitutes < ActiveRecord::Migration
  def change
    create_table :institutes do |t|
      t.string :name
      t.string :url

      t.timestamps
    end
    add_index :institutes, :name
  end
end
