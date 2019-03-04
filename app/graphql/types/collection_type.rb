module Types
  class CollectionType < DriBaseType
    # system generated fields
    # governed_item_ids exists on all objects, 
    # but should only have useful data on collections
    field :governed_item_ids, [ID], null: true # null if collection has no governed items. Should be impossible if collection is published?
  end
end
