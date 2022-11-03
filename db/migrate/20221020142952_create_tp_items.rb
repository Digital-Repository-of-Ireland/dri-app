class CreateTpItems < ActiveRecord::Migration[6.1]
  def change
    create_table :tp_items, id: false, force: :cascade do |t|
      t.string :story_id
      t.string :item_id, null: false, primary_key: true
      t.date :start_date
      t.date :end_date
      t.string :item_link

      t.timestamps
    end
    add_foreign_key :tp_items, :tp_stories, column: :story_id, primary_key: "story_id"
  end
end
