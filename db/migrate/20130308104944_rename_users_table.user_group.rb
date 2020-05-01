# This migration comes from user_group (originally 20121011121140)
class RenameUsersTable < ActiveRecord::Migration[4.2]
	def change
		rename_table :users, :user_group_users
	end
end
