# This migration comes from user_group (originally 20130308110010)
class AddDeviseGuestsToUserGroupUsers < ActiveRecord::Migration
  def self.up
    change_table(:user_group_users) do |t|
      ## Database authenticatable
      t.boolean :guest, :default => false
    end

  end

  def self.down
    # By default, we don't want to make any assumption about how to roll back a migration when your
    # model already existed. Please edit below which fields you would like to remove in this migration.
    raise ActiveRecord::IrreversibleMigration
  end
end