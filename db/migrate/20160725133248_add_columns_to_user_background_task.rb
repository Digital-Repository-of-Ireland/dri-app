class AddColumnsToUserBackgroundTask < ActiveRecord::Migration[4.2]
  def change
    add_column :user_background_tasks, :message, :string
    add_column :user_background_tasks, :status, :string
  end
end
