# This migration comes from user_group (originally 20120926133142)
class AddNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :first_name, :string
    add_column :users, :second_name, :string
  end
end
