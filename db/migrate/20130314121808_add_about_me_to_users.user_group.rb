# This migration comes from user_group (originally 20130314121000)
class AddAboutMeToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :user_group_users, :about_me, :string, :default => ''
  end
end
