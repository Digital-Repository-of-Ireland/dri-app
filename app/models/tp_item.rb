class TpItem < ApplicationRecord
belongs_to :item_id, class_name: 'TpPerson'
belongs_to :item_id, class_name: 'TpPlace'
has_many :story_id, class_name: 'TpStory', foreign_key:'story_id'
end
