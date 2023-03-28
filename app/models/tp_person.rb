class TpPerson < ApplicationRecord
  belongs_to :item, class_name: 'TpItem', optional: true
end
