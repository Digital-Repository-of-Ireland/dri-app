class CreateTpPlaces < ActiveRecord::Migration[6.1]
  def change
    create_table :tp_places do |t|
      t.string :item_id
      t.string :place_id
      t.string :place_name
      t.float :latitude
      t.float :longitude
      t.string :wikidata_id
      t.string :wikidata_name

      t.timestamps
    end
  end
end
