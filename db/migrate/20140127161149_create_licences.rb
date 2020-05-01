class CreateLicences < ActiveRecord::Migration[4.2]
  def change
    create_table :licences do |t|
      t.string :name
      t.string :url
      t.string :logo
      t.string :description

      t.timestamps
    end
  end
end
