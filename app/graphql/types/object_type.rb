module Types
  class ObjectType < DriBaseType
    # required user input fields
    field :type, [String], null: false
    # type available on collection object but can't be set through web form

    # optional user input fields
    # format available on collection, but can't be set through web form
    field :format, [String], null: true
  end
end
