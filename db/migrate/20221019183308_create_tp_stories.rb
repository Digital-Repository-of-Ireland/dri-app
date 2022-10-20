class CreateTpStories < ActiveRecord::Migration[6.1]
  def change
    create_table :tp_stories do |t|
      t.string :story_id
      t.string :dri_id

      t.timestamps
    end
  end
end
