class AddRequestFormToUserGroupMemberships < ActiveRecord::Migration[4.2]
  def change
    add_column :user_group_memberships, :request_form, :text
  end
end
