# This migration comes from user_group (originally 20121004101540)
class AddLockedToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :is_locked, :boolean, default: 0
  end
end
