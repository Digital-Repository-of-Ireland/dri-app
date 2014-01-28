class AddColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :user_group_users, :provider, :string
    add_column :user_group_users, :uid, :string
  end
end
