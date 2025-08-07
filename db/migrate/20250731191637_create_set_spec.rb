class CreateSetSpec < ActiveRecord::Migration[7.2]
  def change
    create_table :set_specs do |t|
      t.string :name
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
