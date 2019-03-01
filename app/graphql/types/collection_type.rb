module Types
  class CollectionType < BaseObject
    field :id, ID, null: false
    field :titles, [String]
  end
end
