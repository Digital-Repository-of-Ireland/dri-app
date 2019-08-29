# This migration comes from user_group (originally 20160701083251)
class AddRequestFormToUserGroupMemberships < ActiveRecord::Migration[4.2]
  def change
    add_column :user_group_memberships, :request_form, :text
  end
end
