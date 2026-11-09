class CreateUserIngests < ActiveRecord::Migration[4.2]
  def change
    create_table :dri_batch_ingest_user_ingests do |t|
      t.references :user, index: true

      t.timestamps null: false
    end

    add_foreign_key :dri_batch_ingest_user_ingests, :user_group_users, column: :user_id
  end
end
