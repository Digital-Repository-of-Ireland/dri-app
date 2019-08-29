# This migration comes from user_group (originally 20130205105143)
class AddLocaleToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :user_group_users, :locale, :string
  end
end
