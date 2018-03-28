class FixityCheck < ActiveRecord::Base
  scope :latest, -> { select('id, collection_id, object_id, MAX(created_at) as created_at, MAX(created_at) as max_created_at').group(:object_id).order('created_at') }
  scope :failed, -> { latest.where(verified: false) }
end