class TpItem < ApplicationRecord
  belongs_to :story, class_name: 'TpStory'
  has_many :people, class_name: 'TpPerson', foreign_key:'item_id'
  has_many :places, class_name: 'TpPlace', foreign_key:'item_id'
end
