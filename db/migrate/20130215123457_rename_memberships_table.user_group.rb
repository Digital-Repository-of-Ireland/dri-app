# This migration comes from user_group (originally 20121011121134)
class RenameMembershipsTable < ActiveRecord::Migration
    def change
        rename_table :memberships, :user_group_memberships
    end
end
