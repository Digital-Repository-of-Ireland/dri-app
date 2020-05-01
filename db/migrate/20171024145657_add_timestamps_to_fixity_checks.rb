class AddTimestampsToFixityChecks < ActiveRecord::Migration[4.2]
  def change
    add_column :fixity_checks, :created_at, :datetime
    add_column :fixity_checks, :updated_at, :datetime
  end
end
