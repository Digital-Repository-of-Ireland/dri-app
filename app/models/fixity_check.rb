class FixityCheck < ActiveRecord::Base
  scope :failed, -> { where(verified: false) }

  belongs_to :fixity_report
end
