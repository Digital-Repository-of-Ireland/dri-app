class CreateFixityReports < ActiveRecord::Migration[5.2]
  def change
    create_table :fixity_reports do |t|

      t.timestamps
    end
  end
end
