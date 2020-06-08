# This migration comes from user_group (originally 20120928145857)
class AddUniquenessToMemberships < ActiveRecord::Migration[4.2]
  def change
    add_index :memberships, [:group_id, :user_id], :unique => true
  end
end
