class CreateUserBackgroundTask < ActiveRecord::Migration
  def change
    create_table :user_background_tasks do |t|
      t.references :user, index: true, foreign_key: true
      t.string :job_id
      t.string :name
    end
  end
end
