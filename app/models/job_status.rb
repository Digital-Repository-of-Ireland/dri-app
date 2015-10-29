class JobStatus < ActiveRecord::Base
  belongs_to :ingest_status
end
