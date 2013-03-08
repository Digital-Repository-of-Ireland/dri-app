# This migration comes from user_group (originally 20121005091213)
class RemoveApprovedFromMembership < ActiveRecord::Migration
  def up
    remove_column :memberships, :approved
  end

  def down
    add_column :memberships, :approved, :boolean
  end
end
