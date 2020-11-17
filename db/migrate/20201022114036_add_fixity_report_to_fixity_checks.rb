class AddFixityReportToFixityChecks < ActiveRecord::Migration[5.2]
  def change
    add_reference :fixity_checks, :fixity_report, foreign_key: true
  end
end
