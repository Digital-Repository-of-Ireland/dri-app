class CreateOrganisationUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :organisation_users do |t|
      t.integer :institute_id
      t.integer :user_id

      t.timestamps
    end

    add_index :organisation_users, [:institute_id, :user_id], :unique => true
  end
end
