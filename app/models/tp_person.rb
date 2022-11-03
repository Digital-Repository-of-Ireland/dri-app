class TpPerson < ApplicationRecord
has_many :item_id, class_name: 'TpItem', foreign_key:'item_id'
end
