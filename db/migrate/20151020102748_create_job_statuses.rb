class CreateJobStatuses < ActiveRecord::Migration[4.2]
  def change
    create_table :job_statuses do |t|
      t.references :ingest_status, index: true
      t.string :job
      t.string :status
      t.string :message

      t.timestamps
    end
  end
end
