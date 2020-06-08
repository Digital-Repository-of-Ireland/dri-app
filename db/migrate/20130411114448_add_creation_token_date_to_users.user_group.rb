# This migration comes from user_group (originally 20130411113254)
class AddCreationTokenDateToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :user_group_users, :token_creation_date, :datetime
  end
end