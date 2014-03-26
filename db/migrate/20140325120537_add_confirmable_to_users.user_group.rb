# This migration comes from user_group (originally 20140325113058)
class AddConfirmableToUsers < ActiveRecord::Migration

  def self.up
    add_column :user_group_users, :confirmation_token, :string
    add_column :user_group_users, :confirmed_at, :datetime
    add_column :user_group_users, :confirmation_sent_at, :datetime
    # add_column :users, :unconfirmed_email, :string # Only if using reconfirmable
    add_index :user_group_users, :confirmation_token, :unique => true
    # User.reset_column_information # Need for some types of updates, but not for update_all.
    # To avoid a short time window between running the migration and updating all existing
    # users as confirmed, do the following
    UserGroup::User.update_all(:confirmed_at => Time.now)
    # All existing user accounts should be able to log in after this.
  end

  def self.down
    remove_columns :user_group_users, :confirmation_token, :confirmed_at, :confirmation_sent_at
  end 

end
