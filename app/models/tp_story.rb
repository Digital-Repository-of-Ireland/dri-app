class TpStory < ApplicationRecord
  has_many :story, class_name: 'TpItem', foreign_key:'story_id'
end
