# This migration comes from user_group (originally 20130312161731)
class AddProfileViewLevelToUser < ActiveRecord::Migration
  def change
    add_column :user_group_users, :view_level, :integer, :default => 0
  end
end
