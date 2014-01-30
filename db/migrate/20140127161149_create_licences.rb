class CreateLicences < ActiveRecord::Migration
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
