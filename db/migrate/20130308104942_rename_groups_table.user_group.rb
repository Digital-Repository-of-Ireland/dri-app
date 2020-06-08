# This migration comes from user_group (originally 20121011121130)
class RenameGroupsTable < ActiveRecord::Migration[4.2]
    def change
        rename_table :groups, :user_group_groups
    end
end
