class CreateTpPeople < ActiveRecord::Migration[6.1]
  def change
    create_table :tp_people do |t|
      t.string :item_id
      t.string :person_id
      t.string :first_name
      t.string :last_name
      t.string :birth_place
      t.date :birth_date
      t.string :death_place
      t.date :death_date
      t.string :person_description

      t.timestamps
    end
  end
end
