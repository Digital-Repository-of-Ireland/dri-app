class TpStory < ApplicationRecord
  has_many :items, class_name: 'TpItem', foreign_key:'story_id'
  has_many :people, class_name: 'TpPerson', through: 'items'
  has_many :places, class_name: 'TpPlace', through: 'items'
end
