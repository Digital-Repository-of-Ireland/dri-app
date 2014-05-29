# This migration comes from user_group (originally 20140526155314)
class RemoveShibColumnsFromUsers < ActiveRecord::Migration
  def up
    remove_column :user_group_users, :provider, :string
    remove_column :user_group_users, :uid, :string
  end

  def down
    add_column :user_group_users, :provider, :string
    add_column :user_group_users, :uid, :string
  end
end
