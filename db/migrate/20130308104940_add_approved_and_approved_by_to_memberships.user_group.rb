# This migration comes from user_group (originally 20121004115440)
class AddApprovedAndApprovedByToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :approved, :boolean, default: 1
    add_column :memberships, :approved_by, :integer
  end
end
