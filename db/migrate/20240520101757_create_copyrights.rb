class CreateCopyrights < ActiveRecord::Migration[6.1]
  def change
    create_table :copyrights do |t|
      t.string :name
      t.string :url
      t.string :logo
      t.string :description

      t.timestamps
    end
  end
end