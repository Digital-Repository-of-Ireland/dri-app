class CreateTpItems < ActiveRecord::Migration[6.1]
  def change
    create_table :tp_items do |t|
      t.string :story_id
      t.string :item_id
      t.date :start_date
      t.date :end_date
      t.string :item_link

      t.timestamps
    end
  end
end
