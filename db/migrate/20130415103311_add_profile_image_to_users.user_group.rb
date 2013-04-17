# This migration comes from user_group (originally 20130415112700)
class AddProfileImageToUsers < ActiveRecord::Migration
  def change
    add_column :user_group_users, :image_link, :string
  end
end