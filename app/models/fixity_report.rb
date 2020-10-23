class FixityReport < ApplicationRecord
  has_many :fixity_checks, dependent: :destroy

  scope :latest, -> { order(created_at: :desc).take }
end
