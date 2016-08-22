class AddColumnsToUserBackgroundTask < ActiveRecord::Migration
  def change
    add_column :user_background_tasks, :message, :string
    add_column :user_background_tasks, :status, :string
  end
end
