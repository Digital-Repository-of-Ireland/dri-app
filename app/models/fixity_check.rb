class FixityCheck < ActiveRecord::Base
  scope :failed, -> { where(verified: false) }
end
