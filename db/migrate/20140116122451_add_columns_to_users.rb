class AddColumnsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :user_group_users, :provider, :string
    add_column :user_group_users, :uid, :string
  end
end
