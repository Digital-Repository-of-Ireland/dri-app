class TpPerson < ApplicationRecord
belongs_to :person, class_name: 'TpItem'
end
