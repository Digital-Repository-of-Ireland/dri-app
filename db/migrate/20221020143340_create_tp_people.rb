class CreateTpPeople < ActiveRecord::Migration[6.1]
  def change
    create_table :tp_people, id: false, force: :cascade do |t|
      t.string :item_id
      t.string :person_id, null: false, primary_key: true
      t.string :first_name
      t.string :last_name
      t.string :birth_place
      t.date :birth_date
      t.string :death_place
      t.date :death_date
      t.string :person_description

      t.timestamps
    end
    add_foreign_key :tp_people, :tp_items, column: :item_id, primary_key: "item_id"
  end
end
