class CreateFixityChecks < ActiveRecord::Migration
  def change
    create_table :fixity_checks do |t|
      t.string :collection_id
      t.string :object_id
      t.boolean :verified
      t.text :result
    end
    add_index :fixity_checks, :collection_id
    add_index :fixity_checks, :object_id
  end
end
