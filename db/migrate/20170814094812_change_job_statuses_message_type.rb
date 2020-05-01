class ChangeJobStatusesMessageType < ActiveRecord::Migration[4.2]
  def self.up
    change_table :job_statuses do |t|
      t.change :message, :text
    end
  end
  def self.down
    change_table :job_statuses do |t|
      t.change :message, :string
    end
  end
end
