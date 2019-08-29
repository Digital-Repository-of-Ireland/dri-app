class CreateBrands < ActiveRecord::Migration[4.2]
  def up
    create_table :brands do |t|
      t.string :filename
      t.string :content_type
      t.binary :file_contents, limit: 1.megabyte
      t.references :institute, index: true

      t.timestamps null: false
    end
  end
end
