 # This migration comes from user_group (originally 20150519150310)
class AddReaderGroupToUserGroupGroups < ActiveRecord::Migration
  def change
    add_column :user_group_groups, :reader_group, :boolean, :default => false
  end
end
