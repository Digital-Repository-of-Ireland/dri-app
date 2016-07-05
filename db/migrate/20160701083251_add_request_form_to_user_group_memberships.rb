class AddRequestFormToUserGroupMemberships < ActiveRecord::Migration
  def change
    add_column :user_group_memberships, :request_form, :text
  end
end
