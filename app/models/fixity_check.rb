class FixityCheck < ActiveRecord::Base
  scope :latest, -> { group(:object_id).having('created_at = MAX(created_at)') }
  scope :failed, -> { latest.where(verified: false) }
end