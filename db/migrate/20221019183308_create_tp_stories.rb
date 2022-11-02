class CreateTpStories < ActiveRecord::Migration[6.1]
  def change
    create_table :tp_stories, id: false do |t|
      t.string :story_id, null: false, primary_key: true
      t.string :dri_id

      t.timestamps
    end
  end
end
