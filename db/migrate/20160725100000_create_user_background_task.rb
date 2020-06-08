class CreateUserBackgroundTask < ActiveRecord::Migration[4.2]
  def change
    create_table :user_background_tasks do |t|
      t.references :user, references: :user_group_users
      t.string :job
      t.string :name
    end
  end
end
