class TpPlace < ApplicationRecord
belongs_to :place, class_name: 'TpItem', optional: true
end
