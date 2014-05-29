# This migration comes from user_group (originally 20140526160017)
class CreateAuthentications < ActiveRecord::Migration
  def up
    create_table :user_group_authentications do |t|
      t.integer :user_id
      t.string :provider
      t.string :uid
    end
  end

  def down
    drop_table :user_group_authentications
  end
end
