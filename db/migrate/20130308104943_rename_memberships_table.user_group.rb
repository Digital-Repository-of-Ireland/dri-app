# This migration comes from user_group (originally 20121011121134)
class RenameMembershipsTable < ActiveRecord::Migration[4.2]
    def change
        rename_table :memberships, :user_group_memberships
    end
end
