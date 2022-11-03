class TpStory < ApplicationRecord
belongs_to :story_id, class_name: 'TpItem'
end
