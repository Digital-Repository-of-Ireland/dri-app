class OrganisationUser < ActiveRecord::Base
  belongs_to :institute
  belongs_to :user, class_name: 'UserGroup::User'

  validates :institute, presence: true
  validates :user, presence: true
end
