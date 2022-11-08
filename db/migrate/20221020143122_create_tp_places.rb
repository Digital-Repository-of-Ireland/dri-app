class CreateTpPlaces < ActiveRecord::Migration[6.1]
  def change
    create_table :tp_places, id: false, force: :cascade do |t|
      t.string :item_id
      t.string :place_id, null: false, primary_key: true
      t.string :place_name
      t.float :latitude
      t.float :longitude
      t.string :wikidata_id
      t.string :wikidata_name

      t.timestamps
    end
    add_foreign_key :tp_places, :tp_items, column: :item_id, primary_key: "item_id"
  end
end
