class IngestStatus < ActiveRecord::Base
  has_many :job_status
end
